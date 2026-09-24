using System;
using System.Diagnostics;
using System.IO;
using System.Text;

namespace DotsPrompt;

public static class Prompt
{
    const string Dir = "\x1b[38;5;31m";
    const string DirAnchor = "\x1b[1;38;5;39m";
    const string Git = "\x1b[38;5;76m";
    const string Ok = "\x1b[38;5;76m";
    const string Error = "\x1b[38;5;196m";
    const string Status = "\x1b[38;5;160m";
    const string Duration = "\x1b[38;5;101m";
    const string Venv = "\x1b[38;5;37m";
    const string Time = "\x1b[38;5;66m";
    const string Reset = "\x1b[0m";

    static string? lastDir;

    public static void SetInitialDirectory(string path) => lastDir = path;

    public static string Render(bool ok, int exitCode, double lastSeconds, string path, bool isFileSystem, string home, int width, string? venv)
    {
        if (isFileSystem && path != lastDir)
        {
            lastDir = path;
            RecordVisit(path);
        }

        string shown = path.StartsWith(home, StringComparison.OrdinalIgnoreCase) ? "~" + path.Substring(home.Length) : path;
        int cut = shown.TrimEnd('\\').LastIndexOf('\\') + 1;

        var left = new StringBuilder();
        left.Append(Dir).Append(shown, 0, cut).Append(DirAnchor).Append(shown, cut, shown.Length - cut).Append(Reset);
        string? branch = isFileSystem ? GitBranch(path) : null;
        if (branch != null) left.Append(' ').Append(Git).Append('').Append(' ').Append(branch).Append(Reset);
        left.Append(' ').Append(ok ? Ok : Error).Append('❯').Append(Reset).Append(' ');

        var right = new StringBuilder();
        int rightWidth = 0;
        void AddRight(string color, string text)
        {
            if (right.Length > 0) { right.Append(' '); rightWidth++; }
            right.Append(color).Append(text);
            rightWidth += text.Length;
        }
        if (!ok) AddRight(Status, "✘ " + (exitCode != 0 ? exitCode : 1));
        if (lastSeconds >= 3) AddRight(Duration, lastSeconds.ToString("N1") + "s ");
        if (!string.IsNullOrEmpty(venv)) AddRight(Venv, Path.GetFileName(venv) + " ");
        AddRight(Time, DateTime.Now.ToString("HH:mm:ss") + " ");
        right.Append(Reset);

        int column = Math.Max(1, width - rightWidth);
        return "\x1b[s\x1b[" + column + "G" + right + "\x1b[u" + left;
    }

    static string? GitBranch(string start)
    {
        string? head = null;
        for (string? dir = start; dir != null; dir = Path.GetDirectoryName(dir))
        {
            string git = Path.Combine(dir, ".git");
            if (Directory.Exists(git)) { head = Path.Combine(git, "HEAD"); break; }
            if (File.Exists(git))
            {
                string gitDir = File.ReadAllText(git).Trim();
                if (gitDir.StartsWith("gitdir:")) gitDir = gitDir.Substring(7).Trim();
                head = Path.Combine(Path.GetFullPath(gitDir, dir), "HEAD");
                break;
            }
        }
        if (head == null || !File.Exists(head)) return null;
        string reference = File.ReadAllText(head).Trim();
        return reference.StartsWith("ref: refs/heads/") ? reference.Substring(16) : reference.Substring(0, 7);
    }

    static void RecordVisit(string path)
    {
        var info = new ProcessStartInfo("zoxide") { CreateNoWindow = true, UseShellExecute = false };
        info.ArgumentList.Add("add");
        info.ArgumentList.Add("--");
        info.ArgumentList.Add(path);
        Process.Start(info)?.Dispose();
    }
}
