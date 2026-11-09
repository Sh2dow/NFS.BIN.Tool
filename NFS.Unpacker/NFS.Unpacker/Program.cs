using System;
using System.IO;

namespace NFS.Unpacker
{
    class Program
    {
        public static String m_Title = "Need for Speed ZDIR Unpacker";

        static void Main(String[] args)
        {
            // Console.Title is Windows-specific, removed for cross-platform compatibility
            Console.ForegroundColor = ConsoleColor.Green;
            Console.WriteLine(m_Title);
            Console.WriteLine("(c) 2024 Ekey (h4x0r) / v{0}\n", Utils.iGetApplicationVersion());
            Console.ResetColor();

            if (args.Length < 3 || args.Length > 4)
            {
                Console.ForegroundColor = ConsoleColor.White;
                Console.WriteLine("[Usage]");
                Console.WriteLine("    NFS.Unpacker <m_Format> <m_File> <m_Directory> [m_Layout]\n");
                Console.WriteLine("    m_Format - ZDIR format (for NFSHP2 PS2 set -true) other games -false");
                Console.WriteLine("    m_File - Source of ZDIR.BIN index file");
                Console.WriteLine("    m_Directory - Destination directory");
                Console.WriteLine("    m_Layout - Optional -flat for loading extracted files directly\n");
                Console.ResetColor();
                Console.ForegroundColor = ConsoleColor.Yellow;
                Console.WriteLine("[Examples]");
                Console.WriteLine("    NFS.Unpacker -false /path/to/ZDIR.BIN /path/to/unpacked");
                Console.WriteLine("    NFS.Unpacker -false /path/to/ZDIR.BIN /path/to/unpacked -flat");
                Console.ResetColor();
                return;
            }

            String m_Format = args[0];
            String m_BinFile = args[1];
            String m_Output = Utils.iCheckArgumentsPath(args[2]);
            Boolean bFlatLayout = args.Length == 4 && args[3] == "-flat";

            if (args.Length == 4 && !bFlatLayout)
            {
                Utils.iSetError("[ERROR]: Unknown layout -> use \"-flat\" or omit it");
                return;
            }

            Boolean bOldZDirFormat = false;
            switch (m_Format)
            {
                case "-false": bOldZDirFormat = false; break;
                case "-true": bOldZDirFormat = true; break;
                default: Utils.iSetError("[ERROR]: Unknown format -> use \"-false\" or \"-true\""); return;
            }

            if (Path.GetFileName(m_BinFile) != "ZDIR.BIN")
            {
                Utils.iSetError("[ERROR]: You must specify ZDIR.BIN file for extract files");
                return;
            }

            if (!File.Exists(m_BinFile))
            {
                Utils.iSetError("[ERROR]: Input file -> " + m_BinFile + " <- does not exist");
                return;
            }

            BinUnpack.iDoIt(m_BinFile, m_Output, bOldZDirFormat, bFlatLayout);
        }
    }
}
