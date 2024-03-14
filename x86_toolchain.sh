#! /bin/bash

# Created by Lubos Kuzma
# Annotated by Ryan Ware, March 2024
# ISS Program, SADT, SAIT
# August 2022

#Check if the number of arguments is less that 1. If less than 1, print instructions below.
if [ $# -lt 1 ]; then
	echo "Usage:"
	echo ""
	echo "x86_toolchain.sh [ options ] <assembly filename> [-o | --output <output filename>]"
	echo ""
	echo "-v | --verbose                Show some information about steps performed."
	echo "-g | --gdb                    Run gdb command on executable."
	echo "-b | --break <break point>    Add breakpoint after running gdb. Default is _start."
	echo "-r | --run                    Run program in gdb automatically. Same as run command inside gdb env."
	echo "-q | --qemu                   Run executable in QEMU emulator. This will execute the program."
	echo "-64| --x86-64                 Compile for 64bit (x86-64) system."
	echo "-o | --output <filename>      Output filename."

	exit 1
fi

POSITIONAL_ARGS=()
GDB=False
OUTPUT_FILE=""
VERBOSE=False
BITS=False
QEMU=False
BREAK="_start"
RUN=False
#Loop through command line arguments.
while [[ $# -gt 0 ]]; do
	case $1 in
		-g|--gdb)
			GDB=True
			shift # past argument. Launch debugger.
			;;
		-o|--output)
			OUTPUT_FILE="$2"
			shift # past argument. Output to ... filename
			shift # past value
			;;
		-v|--verbose)
			VERBOSE=True
			shift # past argument
			;;
		-64|--x84-64)
			BITS=True
			shift # past argument. Choose which architecture x84 or x64.
			;;
		-q|--qemu)
			QEMU=True
			shift # past argument
			;;
		-r|--run)
			RUN=True
			shift # past argument. Run the program.
			;;
		-b|--break)
			BREAK="$2"
			shift # past argument
			shift # past value
			;;
		-*|--*)
			echo "Unknown option $1"
			exit 1
			;;
		*)
			POSITIONAL_ARGS+=("$1") # save positional arg
			shift # past argument
			;;
	esac
done

set -- "${POSITIONAL_ARGS[@]}" # restore positional parameters
#Check if the specified file exists
if [[ ! -f $1 ]]; then
	echo "Specified file does not exist"
	exit 1
fi
#Set default output name to the name of the file if one is not provided
if [ "$OUTPUT_FILE" == "" ]; then
	OUTPUT_FILE=${1%.*}
fi
#Display the verbose information if enabled. Verbose mode provides addition information about the execution of the script
if [ "$VERBOSE" == "True" ]; then
	echo "Arguments being set:"
	echo "	GDB = ${GDB}"
	echo "	RUN = ${RUN}"
	echo "	BREAK = ${BREAK}"
	echo "	QEMU = ${QEMU}"
	echo "	Input File = $1"
	echo "	Output File = $OUTPUT_FILE"
	echo "	Verbose = $VERBOSE"
	echo "	64 bit mode = $BITS" 
	echo ""

	echo "NASM started..."

fi
#Assemble the code based on the arhitecture 32 bit or 64 bit
if [ "$BITS" == "True" ]; then

	nasm -f elf64 $1 -o $OUTPUT_FILE.o && echo ""


elif [ "$BITS" == "False" ]; then

	nasm -f elf $1 -o $OUTPUT_FILE.o && echo ""

fi

if [ "$VERBOSE" == "True" ]; then

	echo "NASM finished"
	echo "Linking ..."
	
fi

if [ "$VERBOSE" == "True" ]; then

	echo "NASM finished"
	echo "Linking ..."
fi
#Link the file based on the mode selected either 32 bit or 64 bit
if [ "$BITS" == "True" ]; then

	ld -m elf_x86_64 $OUTPUT_FILE.o -o $OUTPUT_FILE && echo ""


elif [ "$BITS" == "False" ]; then

	ld -m elf_i386 $OUTPUT_FILE.o -o $OUTPUT_FILE && echo ""

fi


if [ "$VERBOSE" == "True" ]; then

	echo "Linking finished"

fi
#Run is QEMU mode if enabled. Emulator that provides hardware virutalization to allow programs compiled for different architectures to run on current system without the need for acutal hardware.
if [ "$QEMU" == "True" ]; then

	echo "Starting QEMU ..."
	echo ""

	if [ "$BITS" == "True" ]; then
	
		qemu-x86_64 $OUTPUT_FILE && echo ""

	elif [ "$BITS" == "False" ]; then

		qemu-i386 $OUTPUT_FILE && echo ""

	fi

	exit 0
	
fi
#Run debugger if specified
if [ "$GDB" == "True" ]; then

	gdb_params=()
	gdb_params+=(-ex "b ${BREAK}")

	if [ "$RUN" == "True" ]; then

		gdb_params+=(-ex "r")

	fi

	gdb "${gdb_params[@]}" $OUTPUT_FILE

fi
