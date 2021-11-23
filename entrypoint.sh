#!/usr/bin/env bash

function print_usage()
{
   echo
   echo "Docker wrapper for Trimble convertToRinex utility"
   echo "-------------------------------------------------"
   echo
   echo "   Run any command starting with : bash /bin/bash /usr/bin/bash"
   echo "                                   sh /bin/sh /usr/bin/sh"
   echo
   echo "   remember to run container with \"--interactive --tty\" or \"-it\" option"
   echo "   if you expect an interactive shell with prompt"
   echo
   echo "   Otherwise launch a RINEX conversion with original convertToRinex.exe"
   echo "   command line options as shown below."
   echo
   echo "   you need to map a readable/writable volume with \"-v\" or \"--volume\" option"
   echo "   remember that / root directory is mapped to Z:\\ within the wine environment"
   echo "   which is used to wrap and execute convertToRinex.exe"
   echo
   echo "   remember that you need to escape \\ character as \\\\ within path"
   echo
   echo "   example calls converting the provided example MAGC320b.2021.rt27 file, assuming"
   echo "   its in current \$(pwd) directory and \$(pwd) is readable to the user inside container"
   echo "   and \$(pwd)/out is writable to that same user"
   echo
   echo "   docker run --rm -v \"\$(pwd):/data\" mathieupeyrega/trm2rinex:cli-light data/MAGC320b.2021.rt27 -p data/out -v 3.04"
   echo "   docker run --rm -v \"\$(pwd):/data\" mathieupeyrega/trm2rinex:cli-light Z:/data/MAGC320b.2021.rt27 -p Z:/data/out -v 3.04"   
   echo "   docker run --rm -v \"\$(pwd):/data\" mathieupeyrega/trm2rinex:cli-light Z:\\\\data\\\\MAGC320b.2021.rt27 -p Z:\\\\data\\\\out -v 3.04"
   echo
   exec wine cmd /c "C:\\Program Files\\Trimble\\convertToRINEX\\convertToRinex.exe" -? 2>/dev/null
}

if [[ ${#@} -eq 0 ]]
then
    print_usage
else
    case "$1" in
        "help"|"-help"|"--help"|"/help"|"-h"|"--h"|"/h"|"?"|"-?"|"--?"|"/?")
           print_usage
           ;;
        
        "bash"|"/bin/bash"|"/usr/bin/bash"|"sh"|"/bin/sh"|"/usr/bin/sh")
           exec "$@"
           ;;
        
        *)
           exec wine cmd /c "C:\\Program Files\\Trimble\\convertToRINEX\\convertToRinex.exe" "$@" 2>/dev/null
           ;;
   esac
fi

#gosu magc wine cmd /c "C:\\Program Files\\Trimble\\convertToRINEX\\convertToRinex.exe" Z:\\home\\magc\\data\\MAGC320b.2021.rt27 Z:\\home\\magc\\data -v 3.04 2>/dev/null
#exec wine cmd /c "C:\\Program Files\\Trimble\\convertToRINEX\\convertToRinex.exe" "$@" 2>/dev/null

