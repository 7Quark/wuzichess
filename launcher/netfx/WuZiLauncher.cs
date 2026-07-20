using System;
using System.Collections.Generic;
using System.Diagnostics;
using System.Drawing;
using System.IO;
using System.Net;
using System.Net.NetworkInformation;
using System.Net.Sockets;
using System.Reflection;
using System.Threading;
using System.Windows.Forms;

namespace WuZiLauncher
{
    internal static class Program
    {
        private const string MutexName = "WuZiGomoku.NetFx.SingleInstance";

        [STAThread]
        private static void Main(string[] args)
        {
            if (HasArg(args, "--stop"))
            {
                RuntimeState.StopExistingProcess();
                return;
            }

            var noBrowser = HasArg(args, "--no-browser");
            var openOnly = HasArg(args, "--open");

            if (openOnly)
            {
                RuntimeState.OpenExistingUrl();
                return;
            }

            bool createdNew;
            using (var mutex = new Mutex(true, MutexName, out createdNew))
            {
                if (!createdNew)
                {
                    if (!noBrowser)
                    {
                        RuntimeState.OpenExistingUrl();
                    }
                    return;
                }

                Application.EnableVisualStyles();
                Application.SetCompatibleTextRenderingDefault(false);

                try
                {
                    Application.Run(new LauncherContext(noBrowser));
                }
                catch (Exception ex)
                {
                    RuntimeState.WriteLog("Fatal startup error: " + ex);
                    MessageBox.Show(
                        "Launcher failed to start.\r\n" + ex.Message,
                        "WuZi Launcher",
                        MessageBoxButtons.OK,
                        MessageBoxIcon.Error);
                }
            }
        }

        private static bool HasArg(string[] args, string value)
        {
            if (args == null)
            {
                return false;
            }

            for (var i = 0; i < args.Length; i++)
            {
                if (string.Equals(args[i], value, StringComparison.OrdinalIgnoreCase))
                {
                    return true;
                }
            }

            return false;
        }
    }

    internal sealed class LauncherContext : ApplicationContext
    {
        private readonly NotifyIcon trayIcon;
        private readonly EmbeddedHttpServer server;
        private readonly string url;

        public LauncherContext(bool noBrowser)
        {
            RuntimeState.EnsureDirectory();
            RuntimeState.WriteLog("LauncherContext starting.");

            var port = PortHelper.FindFreePort(8765, 8775);
            RuntimeState.WriteLog("Selected port: " + port);
            this.url = "http://127.0.0.1:" + port + "/index.html";
            this.server = new EmbeddedHttpServer(port);
            this.server.Start();
            RuntimeState.WriteLog("HTTP server started.");
            RuntimeState.Save(Process.GetCurrentProcess().Id, port, this.url);
            RuntimeState.WriteLog("State saved.");

            this.trayIcon = new NotifyIcon();
            this.trayIcon.Icon = SystemIcons.Application;
            this.trayIcon.Text = "WuZi Gomoku";
            this.trayIcon.Visible = true;
            this.trayIcon.ContextMenuStrip = BuildMenu();
            this.trayIcon.DoubleClick += delegate { OpenBrowser(); };

            if (!noBrowser)
            {
                RuntimeState.WriteLog("Opening browser.");
                OpenBrowser();
            }
        }

        private ContextMenuStrip BuildMenu()
        {
            var menu = new ContextMenuStrip();
            menu.Items.Add("Open Game", null, delegate { OpenBrowser(); });
            menu.Items.Add("Open Log", null, delegate
            {
                RuntimeState.EnsureDirectory();
                if (!File.Exists(RuntimeState.LogFilePath))
                {
                    File.WriteAllText(RuntimeState.LogFilePath, string.Empty);
                }
                Process.Start(RuntimeState.LogFilePath);
            });
            menu.Items.Add("Open Runtime Folder", null, delegate
            {
                Process.Start(RuntimeState.DirectoryPath);
            });
            menu.Items.Add(new ToolStripSeparator());
            menu.Items.Add("Exit", null, delegate { ExitThread(); });
            return menu;
        }

        private void OpenBrowser()
        {
            Process.Start(this.url);
        }

        protected override void ExitThreadCore()
        {
            RuntimeState.WriteLog("Exit requested.");
            this.trayIcon.Visible = false;
            this.trayIcon.Dispose();
            this.server.Dispose();
            RuntimeState.DeleteState();
            base.ExitThreadCore();
        }
    }

    internal sealed class EmbeddedHttpServer : IDisposable
    {
        private readonly TcpListener listener;
        private readonly Thread worker;
        private readonly Dictionary<string, string> resources;
        private volatile bool disposed;

        public EmbeddedHttpServer(int port)
        {
            this.listener = new TcpListener(IPAddress.Loopback, port);
            this.worker = new Thread(ListenLoop);
            this.worker.IsBackground = true;
            this.resources = BuildResourceMap();
        }

        public void Start()
        {
            this.listener.Start();
            RuntimeState.WriteLog("Listener.Start completed.");
            this.worker.Start();
        }

        private void ListenLoop()
        {
            while (!this.disposed)
            {
                TcpClient client = null;
                try
                {
                    client = this.listener.AcceptTcpClient();
                }
                catch (SocketException)
                {
                    break;
                }
                catch (ObjectDisposedException)
                {
                    break;
                }

                if (client != null)
                {
                    ThreadPool.QueueUserWorkItem(delegate { Handle(client); });
                }
            }
        }

        private void Handle(TcpClient client)
        {
            NetworkStream networkStream = null;
            try
            {
                networkStream = client.GetStream();
                string path;
                if (!TryReadPath(networkStream, out path))
                {
                    return;
                }

                if (string.IsNullOrEmpty(path) || path == "/")
                {
                    path = "/index.html";
                }

                string resourceName;
                if (!this.resources.TryGetValue(path, out resourceName))
                {
                    WriteTextResponse(networkStream, "404 Not Found", "text/plain; charset=utf-8", 404, "Not Found");
                    return;
                }

                using (var stream = Assembly.GetExecutingAssembly().GetManifestResourceStream(resourceName))
                {
                    if (stream == null)
                    {
                        WriteTextResponse(networkStream, "404 Not Found", "text/plain; charset=utf-8", 404, "Not Found");
                        return;
                    }

                    WriteBinaryResponse(networkStream, stream, ContentTypes.Get(path));
                }
            }
            catch
            {
                try
                {
                    if (networkStream != null && networkStream.CanWrite)
                    {
                        WriteTextResponse(networkStream, "500 Internal Server Error", "text/plain; charset=utf-8", 500, "Internal Server Error");
                    }
                }
                catch
                {
                }
            }
            finally
            {
                try
                {
                    if (networkStream != null)
                    {
                        networkStream.Close();
                    }
                    client.Close();
                }
                catch
                {
                }
            }
        }

        private static bool TryReadPath(NetworkStream stream, out string path)
        {
            path = null;
            using (var reader = new StreamReader(stream, System.Text.Encoding.ASCII, false, 1024, true))
            {
                var requestLine = reader.ReadLine();
                if (string.IsNullOrEmpty(requestLine))
                {
                    return false;
                }

                var parts = requestLine.Split(' ');
                if (parts.Length < 2)
                {
                    return false;
                }

                path = parts[1];

                string line;
                do
                {
                    line = reader.ReadLine();
                } while (!string.IsNullOrEmpty(line));

                return true;
            }
        }

        private static void WriteBinaryResponse(NetworkStream stream, Stream content, string contentType)
        {
            var header =
                "HTTP/1.1 200 OK\r\n" +
                "Content-Type: " + contentType + "\r\n" +
                "Content-Length: " + content.Length + "\r\n" +
                "Connection: close\r\n\r\n";
            var headerBytes = System.Text.Encoding.ASCII.GetBytes(header);
            stream.Write(headerBytes, 0, headerBytes.Length);
            content.CopyTo(stream);
        }

        private static void WriteTextResponse(NetworkStream stream, string body, string contentType, int statusCode, string statusText)
        {
            var bodyBytes = System.Text.Encoding.UTF8.GetBytes(body);
            var header =
                "HTTP/1.1 " + statusCode + " " + statusText + "\r\n" +
                "Content-Type: " + contentType + "\r\n" +
                "Content-Length: " + bodyBytes.Length + "\r\n" +
                "Connection: close\r\n\r\n";
            var headerBytes = System.Text.Encoding.ASCII.GetBytes(header);
            stream.Write(headerBytes, 0, headerBytes.Length);
            stream.Write(bodyBytes, 0, bodyBytes.Length);
        }

        private static Dictionary<string, string> BuildResourceMap()
        {
            return new Dictionary<string, string>(StringComparer.OrdinalIgnoreCase)
            {
                { "/index.html", "WuZiLauncher.WebAssets.index.html" },
                { "/src/web/app.js", "WuZiLauncher.WebAssets.src.web.app.js" },
                { "/src/web/styles.css", "WuZiLauncher.WebAssets.src.web.styles.css" },
                { "/assets/scripts/core/gomoku-ai.js", "WuZiLauncher.WebAssets.assets.scripts.core.gomoku-ai.js" },
                { "/assets/scripts/core/gomoku-engine.js", "WuZiLauncher.WebAssets.assets.scripts.core.gomoku-engine.js" },
                { "/assets/scripts/core/gomoku-rules.js", "WuZiLauncher.WebAssets.assets.scripts.core.gomoku-rules.js" }
            };
        }

        public void Dispose()
        {
            this.disposed = true;
            this.listener.Stop();
        }
    }

    internal static class RuntimeState
    {
        public static string DirectoryPath
        {
            get
            {
                return Path.Combine(AppDomain.CurrentDomain.BaseDirectory, ".runtime");
            }
        }

        public static string StateFilePath
        {
            get
            {
                return Path.Combine(DirectoryPath, "launcher-state.txt");
            }
        }

        public static string LogFilePath
        {
            get
            {
                return Path.Combine(DirectoryPath, "launcher.log");
            }
        }

        public static void EnsureDirectory()
        {
            Directory.CreateDirectory(DirectoryPath);
        }

        public static void Save(int processId, int port, string url)
        {
            EnsureDirectory();
            TrimLogIfNeeded();
            File.WriteAllLines(StateFilePath, new[]
            {
                processId.ToString(),
                port.ToString(),
                url
            });
        }

        public static void DeleteState()
        {
            if (File.Exists(StateFilePath))
            {
                File.Delete(StateFilePath);
            }
        }

        public static void WriteLog(string message)
        {
            try
            {
                EnsureDirectory();
                TrimLogIfNeeded();
                File.AppendAllText(
                    LogFilePath,
                    DateTime.Now.ToString("s") + " " + message + Environment.NewLine);
            }
            catch
            {
            }
        }

        private static void TrimLogIfNeeded()
        {
            if (!File.Exists(LogFilePath))
            {
                return;
            }

            var file = new FileInfo(LogFilePath);
            if (file.Length <= 131072)
            {
                return;
            }

            var lines = File.ReadAllLines(LogFilePath);
            var keepFrom = Math.Max(0, lines.Length - 300);
            var keptLines = new string[lines.Length - keepFrom];
            Array.Copy(lines, keepFrom, keptLines, 0, keptLines.Length);
            File.WriteAllLines(LogFilePath, keptLines);
        }

        public static void OpenExistingUrl()
        {
            var state = Load();
            if (state != null && !string.IsNullOrWhiteSpace(state.Url))
            {
                Process.Start(state.Url);
            }
        }

        public static void StopExistingProcess()
        {
            var state = Load();
            if (state == null)
            {
                return;
            }

            try
            {
                var process = Process.GetProcessById(state.ProcessId);
                process.Kill();
                process.WaitForExit(5000);
            }
            catch
            {
            }

            DeleteState();
        }

        private static LauncherState Load()
        {
            if (!File.Exists(StateFilePath))
            {
                return null;
            }

            var lines = File.ReadAllLines(StateFilePath);
            if (lines.Length < 3)
            {
                return null;
            }

            int processId;
            int port;
            if (!int.TryParse(lines[0], out processId) || !int.TryParse(lines[1], out port))
            {
                return null;
            }

            return new LauncherState
            {
                ProcessId = processId,
                Port = port,
                Url = lines[2]
            };
        }
    }

    internal sealed class LauncherState
    {
        public int ProcessId;
        public int Port;
        public string Url;
    }

    internal static class PortHelper
    {
        public static int FindFreePort(int start, int end)
        {
            var active = IPGlobalProperties.GetIPGlobalProperties().GetActiveTcpListeners();

            for (var port = start; port <= end; port++)
            {
                var inUse = false;
                for (var i = 0; i < active.Length; i++)
                {
                    if (active[i].Port == port)
                    {
                        inUse = true;
                        break;
                    }
                }

                if (!inUse)
                {
                    return port;
                }
            }

            throw new InvalidOperationException("No free port found in range 8765-8775.");
        }
    }

    internal static class ContentTypes
    {
        public static string Get(string path)
        {
            if (path.EndsWith(".html", StringComparison.OrdinalIgnoreCase))
            {
                return "text/html; charset=utf-8";
            }

            if (path.EndsWith(".css", StringComparison.OrdinalIgnoreCase))
            {
                return "text/css; charset=utf-8";
            }

            if (path.EndsWith(".js", StringComparison.OrdinalIgnoreCase))
            {
                return "text/javascript; charset=utf-8";
            }

            return "application/octet-stream";
        }
    }
}
