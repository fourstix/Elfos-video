//++
//romtext
//
//    This program will convert a plain ASCII text file into an Intel format
// HEX file.  It's pretty simple - the only real nifty things it does are to
// allow you to specify the starting address for the HEX file image, and to
// ingore comments in the source file.
//
// USAGE:
//  romtext [-annnn] input-file output-file ...
//
//		-annnn - set the address of the output image
//
// REVISION HISTORY
// 22-Feb-06	RLA	New file...
//--
#include <stdio.h>		// printf(), scanf(), et al.
#include <stdlib.h>		// exit(), ...
#include <malloc.h>		// malloc(), _fmalloc(), etc...
#include <memory.h>		// memset(), etc...
#include <string.h>
#include <Windows.h>

#define ROMSIZE	((unsigned) 65535)	// largest file we can convert!
#define MAXLINE 512					// longest line possible

typedef unsigned char uchar;

// Globals...
unsigned uROMAddress;// offset of the EPROM in memory



//++
//WriteHex
//
//   This function will write an array of bytes to a file in standard Intex
// .HEX file format.  Only the traditional 16 bit format is supported and
// so the array must be 64K or less.  The only records generated are type 00
// (data) and 01 (end of file).  This routine always writes everything in
// the array and doesn't attempt to remove filler bytes...
//--
void WriteHex (
  FILE      *fOutput,	// handle of the .HEX file to be written
  uchar far *Data,		// array of bytes to be saved
  long       Count,		// number of bytes to write
  unsigned uOffset)		// offset applied to input records
{
  unsigned Address = 0;	// address of the current record
  unsigned RecordSize;	// size of the current record
  unsigned RecordAddress;
  int      Checksum;	// checksum "  "     "       "
  unsigned i;			// temporary...


  while (Count > 0) {
    RecordSize = (Count > 16) ? 16 : (unsigned) Count;
    RecordAddress = (Address+uOffset) & 0xFFFF;
    fprintf(fOutput,":%02X%04X00", RecordSize, RecordAddress);
    Checksum = RecordSize + (RecordAddress >> 8) + (RecordAddress & 0xFF) + 00 /* Type */;
    for (i = 0;  i < RecordSize;  ++i) {
      fprintf(fOutput,"%02X", *(Data+Address+i));
      Checksum += *(Data+Address+i);
    }
    fprintf(fOutput,"%02X\n", (-Checksum) & 0xFF);
    Count -= RecordSize;  Address += RecordSize;
  }
  
  fprintf(fOutput, ":00000001FF\n");
}


//++
//   This function parses the command line and initializes all the global
// variables accordingly.  It's tedious, but fairly brainless work.  Note
// that NO file names are required - if none are supplied, stdin and stdout
// are used instead...
//--
int ParseOptions (int argc, char *argv[])
{
  int nArg;  char *psz;

  // First, set all the defaults...
  uROMAddress = 0;

  // If there are no arguments, then just print the help and exit...
  if (argc == 1) {
    fprintf(stderr, "Usage:\n");
    fprintf(stderr,"romtext [-annnn] [input-file] [output-file]\n");
    fprintf(stderr,"\t-annnn - set the address of the ROM image\n");
    exit(EXIT_SUCCESS);
  }

  for (nArg = 1;  nArg < argc;  ++nArg) {
    // If it doesn't start with a "-" character, then it must be a file name.
    if (argv[nArg][0] != '-') return nArg;

    // Handle the -a (address) option...
    if (strncmp(argv[nArg], "-a", 2) == 0) {
      uROMAddress = (unsigned) strtoul(argv[nArg]+2, &psz, 10);
      if ((*psz == 'x') && (uROMAddress == 0))
        uROMAddress = (unsigned) strtoul(psz+1, &psz, 16);
      if ((*psz != '\0') || (uROMAddress > 0xFFFF)) {
        fprintf(stderr, "romtext: illegal address: \"%s\"", argv[nArg]);
        exit(EXIT_FAILURE);
      }
      continue;
    }

    // Otherwise it's an illegal option...
    fprintf(stderr, "romtext: unknown option - \"%s\"\n", argv[nArg]);
    exit(EXIT_FAILURE);
  }

  return nArg;  
}


//++
// ReadText
//--
unsigned ReadText (FILE *fInput, uchar far *lpbData, unsigned uMaxSize)
{
  char szLine[MAXLINE];  unsigned uTextSize = 0;
  
  while (fgets(szLine, MAXLINE, fInput) != NULL) {
    char *psz;  int len = strlen(szLine);
    // Ignore comments...
    if ((len > 0) && (szLine[0] == '#')) continue;
    // Convert the line ending to <CRLF> regardless of what we read...
    if ((len > 0) && (szLine[len-1] == '\n')) szLine[--len] = 0;
    strcat(szLine, "\r\n");  len += 2;
    // Append the line to the buffer ...
    for (psz = szLine;  *psz != 0;  ++psz) {
      if (uTextSize++ < uMaxSize) *lpbData++ = *psz;
    }
  } 
  // Always end with a null byte!
  if (uTextSize++ < uMaxSize) *lpbData++ = 0;
  return uTextSize;
}


//++
//main
//--
void main (int argc, char *argv[])
{
  unsigned uTextSize;  FILE *fInput, *fOutput;
  char *pszInput;  uchar far *lpbData;  int nArg;
 
  nArg = ParseOptions(argc, argv);
  //fprintf(stderr,"Start Address = %u (0x%04x)\n", uROMAddress, uROMAddress);
  
  //   If either the input file, the output file, or both is absent then
  // they default to stdin and stdout.  If only one is present, then its
  // the input file...
  if (nArg <argc) {
    //fprintf(stderr,"Input file = %s\n", argv[nArg]);
    fInput = fopen(argv[nArg], "r");  pszInput = argv[nArg];
    if (fInput == NULL) {
      fprintf(stderr,"romtext: can't read %s\n", argv[nArg]);
      exit(EXIT_FAILURE);
    }
    ++nArg;
  } else {
    fInput = stdin;  pszInput = "";
  }
  if (nArg < argc) {
    //fprintf(stderr,"Output file = %s\n", argv[nArg]);
    fOutput = fopen(argv[nArg], "w");
    if (fOutput == NULL) {
      fprintf(stderr,"romtext: can't write %s\n", argv[nArg]);
      exit(EXIT_FAILURE);
    }
    ++nArg;
  } else
    fOutput = stdout;

  // If there are any arguments left, it's an error...
  if (nArg < argc) {
    fprintf(stderr,"romtext: extra arguments \"%s\"\n", argv[nArg]);
    exit(EXIT_FAILURE);
  }
      
  // Allocate a buffer to hold the ROM image ...
  lpbData = (uchar far *) calloc((size_t) ROMSIZE, 1);
  if (lpbData == NULL) {
    fprintf(stderr,"romtext: failed to allocate memory\n");
    exit(1);
  } 
  memset(lpbData, 0xFF, (size_t) ROMSIZE);

  // Load the input file...
  //..
  uTextSize = ReadText(fInput, lpbData, ROMSIZE);

  // Dump out the ROM image and we're all done...
  WriteHex(fOutput, lpbData, uTextSize, uROMAddress);
  printf("%s: %u bytes from 0x%04X to 0x%04X\n",
    pszInput, uTextSize, uROMAddress, uROMAddress+uTextSize-1);

  exit(0);  
}
