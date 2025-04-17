// fixes order of font from Atari to ASCII. Not used.

#include <stdio.h>
#include <string.h>

unsigned char chset[1024];

int main() {
	FILE* fp = fopen("vt_orig.fnt", "rb");
	memset(chset, 0x1, 1024);
	fread(chset, 8, 128, fp);
	fclose(fp);
	fp = fopen("vt.fnt", "wb");
	fwrite(chset+64*8, 8, 32, fp);
	fwrite(chset, 8, 64, fp);
	fwrite(chset+96*8, 8, 32, fp);
	fclose(fp);
}