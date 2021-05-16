//++
//rommerge
//
//   This program will merge multiple Intel .HEX files and write a new .HEX
// file for the resulting ROM image.  One side effect of this program is that
// it also fills unused bytes in the ROM image, and writes these fillers out
// to the new HEX file.  Normally the filler is 0x00, but an alternate value
// may be specified on the command line.
//
// USAGE:
//  rommerge [-snnnn] [-onnnn] [-fnn] output-file input-file-1 input-file-2 input-file-3 ...
//
//		-snnnn - set the ROM size in bytes (e.g. -s32k or -s32768)
//      -onnnn - set the offset for the output image
//			     (e.g. -o32k starts the output image at 0x8000)
//	    -fnn   - set the filler byte to nn decimal (e.g. -f0 or -f255)
//
// NOTE:
//   This program will work for ROMs up to 64K, which requires that longs
// be used to sizes and counts...
//
// REVISION HISTORY
// 24-Feb-05	RLA	New file...
//--
#include <stdio.h>		// printf(), scanf(), et al.
#include <stdlib.h>		// exit(), ...
#include <malloc.h>		// malloc(), _fmalloc(), etc...
#include <memory.h>		// memset(), etc...
#include <string.h>
#include <windows.h>

typedef unsigned char uchar;

// Globals...
long  lROMSize;		// size of the ROM, in bytes (e.g. 65536)
uchar uFillByte;	// filler value for unused ROM locations
unsigned uROMOffset;	// offset of the EPROM in memory
uchar far *lpbData;	// pointer to the ROM image buffer
long lByteCount;	// count of bytes loaded from the .HEX file
char *szOutputFile;	// output file name



//++
//ReadHex
//
//   This function will load a standard Intel format .HEX file into memory.
// Only the traditional 16-bit address format is supported, which puts an
// upper limit of 64K on the amount of data which may be loaded.  Only
// record types 00 (data) and 01 (end of file) are recognized.
//
//   The number of bytes read will be returned as the function's value,
// and this will be zero if any error occurs.  Note that all counts, sizes
// and offsets must be longs on the off chance that exactly 64K bytes will
// be read!
//--
long ReadHex (		// returns count of bytes read, or zero if error
  char      *Name,	// name of the .HEX file to be loaded
  uchar far *Data,	// this array receives the data loaded
  long       Size,	// maximum size of the array, in bytes
  unsigned   uOffset)	// offset applied to input records
{
  FILE	   *f;		// handle of the input file
  long      Count = 0;	// number of bytes loaded from file
  unsigned  Length;	// length       of the current .HEX record
  unsigned  Address;	// load address "   "     "      "     "
  unsigned  Type;	// type         "   "     "      "     "
  unsigned  Checksum;	// checksum     "   "     "      "     "
  unsigned  Byte;	// temporary for the data byte read...
  
  if ((f=fopen(Name, "rt")) == NULL)
    {fprintf(stderr,"%s: unable to open file\n", Name);  return 0;}

  while (1) {
    if (fscanf(f,":%2x%4x%2x",&Length,&Address,&Type) != 3)
      {fprintf(stderr,"%s: bad .HEX file format (1)\n", Name);  return 0;}
    if (Type > 1)
      {fprintf(stderr,"%s: unknown record type\n", Name);  return 0;}
    Checksum = Length + (Address >> 8) + (Address & 0xFF) + Type;
    for (;  Length > 0;  --Length, ++Address, ++Count) {
      if (fscanf(f,"%2x",&Byte) != 1)
        {fprintf(stderr,"%s: bad .HEX file format (2)\n", Name);  return 0;}
      if ((long)((Address - uOffset) & 0xFFFF) >= Size)
        {fprintf(stderr,"%s: address outside ROM\n", Name);  return 0;}
      if (Data[(Address-uOffset) & 0xFFFF] == uFillByte) 
        Data[(Address-uOffset) & 0xFFFF] = (uchar) Byte;
      else if (Byte != uFillByte) {
        printf("%s: conflict at address 0x%04X\n", Name, Address);  return 0;
      }
      Checksum += Byte;
    }
    if (fscanf(f,"%2x\n",&Byte) != 1)
      {fprintf(stderr,"%s: bad .HEX file format (3)\n", Name);  return 0;}
    Checksum = (Checksum + Byte) & 0xFF;
    if (Checksum != 0)
      {fprintf(stderr,"%s: checksum error\n", Name);  return 0;}
    if (Type == 1) break;
  }
  
  fclose(f);
  return Count;
}


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
  char      *Name,	// name of the .HEX file to be written
  uchar far *Data,	// array of bytes to be saved
  long       Count,	// number of bytes to write
  unsigned uOffset)	// offset applied to input records
{
  FILE *f;		// handle of the output file
  unsigned Address = 0;	// address of the current record
  unsigned RecordSize;	// size of the current record
  unsigned RecordAddress;
  int      Checksum;	// checksum "  "     "       "
  unsigned i;		// temporary...

  if ((f=fopen(Name, "wt")) == NULL)
    {fprintf(stderr,"%s: unable to write file\n", Name);  return;}

  while (Count > 0) {
    RecordSize = (Count > 16) ? 16 : (unsigned) Count;
    RecordAddress = (Address+uOffset) & 0xFFFF;
    fprintf(f,":%02X%04X00", RecordSize, RecordAddress);
    Checksum = RecordSize + (RecordAddress >> 8) + (RecordAddress & 0xFF) + 00 /* Type */;
    for (i = 0;  i < RecordSize;  ++i) {
      fprintf(f,"%02X", *(Data+Address+i));
      Checksum += *(Data+Address+i);
    }
    fprintf(f,"%02X\n", (-Checksum) & 0xFF);
    Count -= RecordSize;  Address += RecordSize;
  }
  
  fprintf(f, ":00000001FF\n");  fclose(f);
}


//++
//   This function parses the command line and initializes all the global
// variables accordingly.  It's tedious, but fairly brainless work.  All
// options, if there are any, are required to be first on the command line.
// The first non-option parameter is the output file name, and all parameters
// after that are input files.  This routine parses just the options and it
// returns the index of the output file name.
//--
int ParseOptions (int argc, char *argv[])
{
  int nArg;  char *psz;

  // First, set all the defaults...
  lROMSize = 65536;  uROMOffset = 0;  uFillByte = 0xFF;

  // If there are no arguments, then just print the help and exit...
  if (argc == 1) {
    fprintf(stderr, "Usage:\n");
    fprintf(stderr,"rommerge [-snnnn] [-onnnn] [-fnn] output-file input-file-1 input-file-2 ...\n");
    fprintf(stderr,"\t-snnnn - set the ROM size in bytes (e.g. -s32k or -s32768)\n");
    fprintf(stderr,"\t-onnnn - set the offset for the output image (e.g. -o32768)\n");
    fprintf(stderr,"\t-fnn   - set the filler byte to nn decimal (e.g. -f0 or -f255)\n");
    exit(EXIT_SUCCESS);
  }

  for (nArg = 1;  nArg < argc;  ++nArg) {
    // If it doesn't start with a "-" character, then it must be a file name.
    if (argv[nArg][0] != '-') {
      //   At least two MORE arguments - this output file and two input files - are
      // still required!
      if (nArg+2 > argc) {
        fprintf(stderr,"rommerge: not enough file names\n");
        exit(EXIT_FAILURE);
      }
      return nArg;
    }

    // Handle the -o (offset) option...
    if (strncmp(argv[nArg], "-o", 2) == 0) {
      uROMOffset = (unsigned) strtoul(argv[nArg]+2, &psz, 10);
      if (*psz == 'k' || *psz == 'K')   uROMOffset <<= 10, ++psz;
      if ((*psz != '\0') || (uROMOffset > 0xFFFF)) {
        fprintf(stderr, "rommerge: illegal offset: \"%s\"", argv[nArg]);
        exit(EXIT_FAILURE);
      }
      continue;
    }

    // Handle the -s (ROM size) option...
    if (strncmp(argv[nArg], "-s", 2) == 0) {
      lROMSize = strtoul(argv[nArg]+2, &psz, 10);
      if (*psz == 'k' || *psz == 'K')   lROMSize <<= 10, ++psz;
      if (*psz != '\0') {
        fprintf(stderr,"rommerge: invalid ROM size \"%s\"\n", argv[nArg]);
        exit(EXIT_FAILURE);
      }
      continue;
    }

    // Handle the -f (fill byte) option...
    if (strncmp(argv[nArg], "-f", 2) == 0) {
      uFillByte = (unsigned) strtol(argv[nArg]+2, &psz, 10);
      if (*psz != '\0') {
        fprintf(stderr,"rommerge: invalid fill byte \"%s\"\n", argv[nArg]);
        exit(EXIT_FAILURE);
      }
      continue;
    }

    // Otherwise it's an illegal option...
    fprintf(stderr, "rommerge: unknown option - \"%s\"\n", argv[nArg]);
    exit(EXIT_FAILURE);
  }
  
  // If we get here, there's no file name...
  fprintf(stderr,"rommerge: specify a file name\n");
  exit(EXIT_FAILURE);
}


//++
//main
//--
void main (int argc, char *argv[])
{
  int nFile;  long i;
 
  nFile = ParseOptions(argc, argv);
  szOutputFile = argv[nFile++];
  //fprintf(stderr,"Output file = %s\n", szOutputFile);
  //fprintf(stderr,"ROM Size        = %ld (0x%05lx)\n", lROMSize, lROMSize);
  //fprintf(stderr,"Fill Byte       = %u   (0x%02x)\n", uFillByte, uFillByte);
  //fprintf(stderr,"ROM Offset      = %u (0x%05x)\n", uROMOffset, uROMOffset);
 
  // Allocate a buffer to hold the ROM image and fill it with the filler value.
  lpbData = (uchar far *) calloc((size_t) lROMSize, 1);
  if (lpbData == NULL) {
    fprintf(stderr,"rommerge: failed to allocate memory\n");
    exit(1);
  }
  for (i = 0;  i < lROMSize;  ++i)  lpbData[i] = uFillByte;

  // Load all the input files...
  for (lByteCount = 0; nFile < argc;  ++nFile) {
    long lBytes;
    lBytes = ReadHex(argv[nFile], lpbData, lROMSize, uROMOffset);
    printf("%s: %ld bytes read\n", argv[nFile], lBytes);
    lByteCount += lBytes;
  }
  if (lByteCount == 0)  exit(1);

  // Dump out the new ROM image and we're all done...
  WriteHex(szOutputFile, lpbData, lROMSize, uROMOffset);
  printf("%s: %ld bytes written\n", szOutputFile, lByteCount);

  exit(0);  
}
