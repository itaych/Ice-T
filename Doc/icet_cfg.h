// Structure and contents of the ICET.DAT configuration file, in C header format.

#include <stdint.h>

struct icet_config_t {
	uint8_t baudrate = 15; // Serial port baud rate: 8-15 for 300, 600, 1200, 1800, 2400, 4800, 9600, 19200 baud respectively.
	uint8_t stopbits = 0; // Serial port stop bits: 0 for 1, 128 for 2.
	uint8_t localecho = 0; // Local Echo: 0 for off, 1 for on.
	uint8_t click = 2; // Key click type: 0 for no click, 1 for single write to console speaker register, 2 for Atari OS keyclick.
	uint8_t curssiz = 6; // Cursor size: 0 for a block, 6 for underline.
	uint8_t finescrol = 0; // Enable fine scroll: 0 to disable, 4 to enable. Only one of finescrol or boldallw may be nonzero.
	uint8_t boldallw = 1; // Enable additional graphics: 0 to disable, 1 for ANSI colors, 2 for bold only, 3 to enable blinking text.
	uint8_t autowrap = 1; // Wrap around at edge of screen. 1 to enable (normal behavior), 0 to disable.
	uint8_t delchr = 0; // Bits 0-1: Code to send for Backspace key. 0 - $7f (DEL), 1 - $08 (^H, BS), 2 - $7e (Atari backspace)
						//  Bits 2-3: Code to send for Return key. 0 for VT100 default, 1 for CR, 2 for LF, 3 for CR+LF.
	uint8_t bckgrnd = 0; // Screen display mode: 0 for light text on dark background, 1 for reverse.
	uint8_t bckcolr = 0; // Hue of screen background, 0-15.
	uint8_t eoltrns = 0; // Downloaded files EOL translation. 0-3 for None/CR/LF/Either. See documentation for details.
	uint8_t ansiflt = 0; // Strip ANSI codes from captured files. 0 for no effect, 1 to activate filtering.
	uint8_t ueltrns = 3; // EOL translation for ASCII uploads. 0-3 for CRLF/CR/LF/None. See documentation for details.
	uint8_t ansibbs = 0; // Terminal emulation: 0 for VT-102, 1 for ANSI-BBS, 2 for VT-52.
	uint8_t eitbit = 1; // Enables PC graphical character set for values 128 and above: 0 to disable, 1 to enable.
	uint8_t fastr = 2; // Frequency of status calls to serial port device. 0 for normal, 1 for medium, 2 for constant.
	uint8_t flowctrl = 1; // Flow control method: 0-3 for None, Xon/Xoff, "Rush", Both.
	uint8_t eolchar = 0; // EOL handling for terminal. 0=CR/LF, 1=LF alone, 2=CR alone, 3=ATASCII ($9b)
		// (in mode 3, ATASCII Tabs are also accepted as a tab character)
	uint8_t ascdelay = 2; // In ASCII upload: 0 for no delay between lines, 1-7 for some delay, higher value waits for that character
		// to arrive from the remote side. Delay values are 1/60 sec, 1/10 sec, 1.5 sec, 1/2 sec, 1 sec, 1.5 sec, 2 sec.

    // Dialer entries (names and numbers) and macro data are standard ASCII strings.
    // They are padded with null bytes if they do not occupy their full capacity, but
    // do not require a null terminator if they fill their entire space.

	// Stored autodial entries
	struct dialer_entry_t {
		char name[40];
		char number[40];
	};
	dialer_entry_t dialdat[20];

	// Macro key assignments. 12 bytes for 12 macros.
	// 0-9 or A-Z (ASCII values, letters are upper case) or null for no macro.
	char macro_key_assign[12];

	// reserved for possible additional macros or other future use.
	char reserved[4];

	// Macro data. 12 macros of up to 64 bytes each.
	char macro_data[12][64];
};
