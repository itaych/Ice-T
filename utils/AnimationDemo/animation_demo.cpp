#include <stdio.h>
#include <stdint.h>
#include <string>
#include <string.h>
#include <vector>

using namespace std;

const char* fuji_logo[] = {
"                 XXXX XXXXXXXX XXXX                 ",
"                 XXXX XXXXXXXX XXXX                 ",
"                 XXXX XXXXXXXX XXXX                 ",
"                 XXXX XXXXXXXX XXXX                 ",
"                 XXXX XXXXXXXX XXXX                 ",
"                 XXXX XXXXXXXX XXXX                 ",
"                 XXXX XXXXXXXX XXXX                 ",
"                 XXXX XXXXXXXX XXXX                 ",
"                 XXXX XXXXXXXX XXXX                 ",
"                 XXXX XXXXXXXX XXXX                 ",
"                 XXXX XXXXXXXX XXXX                 ",
"                 XXXX XXXXXXXX XXXX                 ",
"                 XXXX XXXXXXXX XXXX                 ",
"                XXXXX XXXXXXXX XXXXX                ",
"                XXXXX XXXXXXXX XXXXX                ",
"                XXXXX XXXXXXXX XXXXX                ",
"                XXXXX XXXXXXXX XXXXX                ",
"               XXXXXX XXXXXXXX XXXXXX               ",
"               XXXXXX XXXXXXXX XXXXXX               ",
"              XXXXXX  XXXXXXXX  XXXXXX              ",
"              XXXXXX  XXXXXXXX  XXXXXX              ",
"             XXXXXXX  XXXXXXXX  XXXXXXX             ",
"             XXXXXX   XXXXXXXX   XXXXXX             ",
"            XXXXXXX   XXXXXXXX   XXXXXXX            ",
"           XXXXXXXX   XXXXXXXX   XXXXXXXX           ",
"          XXXXXXXX    XXXXXXXX    XXXXXXXX          ",
"         XXXXXXXXX    XXXXXXXX    XXXXXXXXX         ",
"        XXXXXXXXX     XXXXXXXX     XXXXXXXXX        ",
"      XXXXXXXXXX      XXXXXXXX      XXXXXXXXXX      ",
"   XXXXXXXXXXXXX      XXXXXXXX      XXXXXXXXXXXXX   ",
"XXXXXXXXXXXXXXX       XXXXXXXX       XXXXXXXXXXXXXXX",
"XXXXXXXXXXXXXX        XXXXXXXX        XXXXXXXXXXXXXX",
"XXXXXXXXXXXXX         XXXXXXXX         XXXXXXXXXXXXX",
"XXXXXXXXXXX           XXXXXXXX           XXXXXXXXXXX",
"XXXXXXXXX             XXXXXXXX             XXXXXXXXX",
"XXXXXX                XXXXXXXX                XXXXXX",
};

void send_code_args(const vector<uint8_t>& v, const std::string& code) {
	printf("\e[");
	for (size_t i=0; i<v.size(); i++) {
		if (i) {
			printf(";");
		}
		printf("%d", v[i]);
	}
	printf("%s", code.c_str());
}

void send_sgr(const vector<uint8_t>& v) {
	send_code_args(v, "m");
}

void set_position(uint8_t x, uint8_t y) {
	send_code_args({y, x}, "H");
}

void set_scroll_margins(uint8_t top=1, uint8_t bot=24) {
	send_code_args({top, bot}, "r");
}

void reset_scroll_margins() {
	send_code_args({}, "r");
}

void clear_screen() {
	send_code_args({2}, "J");
}

void clear_line() {
	send_code_args({2}, "K");
}

void send_priv_code(const vector<uint8_t>& v) {
	send_code_args(v, "/t");
}

void vdelay(uint8_t delay = 0) {
	if (!delay) {
		send_priv_code({1});
	}
	else {
		send_priv_code({1, delay});
	}
}

void blit_bold(uint8_t x, uint8_t y, uint8_t x2=1, uint8_t y2=1) {
	send_priv_code({2, y, x, y2, x2});
}

void set_underlay_colors(uint8_t pm_col, uint8_t y, vector<uint8_t> v) {
	v.insert(v.begin(), pm_col);
	v.insert(v.begin(), y);
	v.insert(v.begin(), 3);
	send_priv_code(v);
}

void set_scroll_lock(uint8_t val) {
	send_priv_code({4, val});
}

void colors_vert_scroll_down(uint8_t num_lines=1, uint8_t scroll_bitmap=1,
	uint8_t scroll_colors=1, uint8_t rotate=0) {
	send_priv_code({5, num_lines, scroll_bitmap, scroll_colors, rotate});
}

void colors_vert_scroll_up(uint8_t num_lines=1, uint8_t scroll_bitmap=1,
	uint8_t scroll_colors=1, uint8_t rotate=0) {
	send_priv_code({6, num_lines, scroll_bitmap, scroll_colors, rotate});
}

void set_screen_colors(vector<uint8_t> v) {
	v.insert(v.begin(), 10);
	send_priv_code(v);
}

void set_pm_control(uint8_t pnum, uint8_t horiz, int width = -1, int color = -1) {
	vector<uint8_t> v = {11, pnum, horiz};
	if (width >= 0) v.push_back(width);
	if (color >= 0) v.push_back(color);
	send_priv_code(v);
}

void pm_fill(uint8_t pnum, uint8_t start=0, uint8_t size=128, uint8_t data=0) {
	vector<uint8_t> v = {13, pnum, start, size, data};
	send_priv_code(v);
}

void set_pm_shape(uint8_t pnum, uint8_t start, vector<uint8_t> v) {
	v.insert(v.begin(), start);
	v.insert(v.begin(), pnum);
	v.insert(v.begin(), 14);
	send_priv_code(v);
}

void pm_vert_move(uint8_t pnum, uint8_t src, uint8_t dst, uint8_t size) {
	vector<uint8_t> v = {15, pnum, src, dst, size};
	send_priv_code(v);
}

void set_line_size(uint8_t size) {
	printf("\e#%d", size);
}

void reset_terminal() {
	printf("\ec");
}

void write_centered_large_text(int line, const string& msg, bool repeat) {
	int x = 20-msg.size()/2;
	set_position(x, line);
	printf("%s", msg.c_str());
	if (repeat) {
		set_position(x, line+1);
		printf("%s", msg.c_str());
	}
}

void write_centered_text(int line, const string& msg) {
	int x = 40-msg.size()/2;
	set_position(x, line);
	printf("%s", msg.c_str());
}

void unfade(int first_row, int last_row) {
	vector<uint8_t> colors(5 * (last_row-first_row+1));
	for (int i=0; i<=12; i+=2) {
		std::fill(colors.begin(), colors.end(), i);
		set_underlay_colors(1, first_row, colors);
		vdelay(2);
	}
}

void fade(int first_row, int last_row) {
	vector<uint8_t> colors(5 * (last_row-first_row+1));
	for (int i=12; i>=0; i-=2) {
		std::fill(colors.begin(), colors.end(), i);
		set_underlay_colors(1, first_row, colors);
		vdelay(2);
	}
}

uint8_t flip_bits(uint8_t val) {
	uint8_t ret = 0;
	for (int i=0; i<8; i++) {
		ret |= (val & 1) << (7-i);
		val >>= 1;
	}
	return ret;
}

int main() {
	reset_terminal();
	set_screen_colors({0, 10, 2}); // see sccolors in vtv.asm. Default Ice-T colors for hue 0, dark background.

	// phase 1: show some silly titles similar to MS Windows welcome for new users.
	if (true) {
		int y_pos_headings = 10;
		set_position(1,y_pos_headings);
		set_line_size(3);
		set_position(1,y_pos_headings+1);
		set_line_size(4);
		send_sgr({48,9,0}); // black color
		write_centered_large_text(y_pos_headings, "Hi.", true);
		vdelay(60);
		unfade(y_pos_headings, y_pos_headings+1);
		vdelay(60*3);
		fade(y_pos_headings, y_pos_headings+1);
		write_centered_large_text(y_pos_headings, "Getting things ready for you.", true);
		unfade(y_pos_headings, y_pos_headings+1);
		vdelay(60*3);
		fade(y_pos_headings, y_pos_headings+1);
		write_centered_large_text(y_pos_headings, "This might take a few minutes.", true);
		write_centered_text(y_pos_headings+2, "Don't turn off your PC");
		unfade(y_pos_headings, y_pos_headings+2);
		vdelay(60*3);
		fade(y_pos_headings, y_pos_headings+2);
		// clearing the entire screen will briefly flash the text so clear the lines instead
		set_position(1,y_pos_headings);
		clear_line();
		set_position(1,y_pos_headings+1);
		clear_line();
		set_position(1,y_pos_headings+2);
		clear_line();
		send_sgr({});
		clear_screen(); // to reset colors, line sizes etc.
	}

	// phase 2: fuji logo with rainbow colors.
	if (true) {
		int x, y;
		// calculate position of fuji
		int fuji_width = strlen(fuji_logo[0]);
		int fuji_height = sizeof(fuji_logo)/sizeof(const char*)/2;

		int top_left_x = (80-fuji_width)/2;
		int top_left_y = 2;
		int slogan_row = top_left_y+fuji_height+2;

		send_sgr({38,9,0}); // black color

		// draw the logo
		for (y=0; y<fuji_height; y++) {
			const char* s1 = fuji_logo[y*2];
			const char* s2 = fuji_logo[y*2+1];
			std::string out_str(strlen(s1), ' ');

			// convert two lines to one
			for (x=0; x<(int)strlen(s1); x++) {
				char c_type = (s1[x] == ' '? 0 : 1) | (s2[x] == ' '? 0 : 2);
				const uint8_t c_chars[] = { ' ', 223, 220, 219 };
				out_str[x] = c_chars[(int)c_type];
			}

			// count leading and trailing spaces
			int first_valid_char_position = out_str.size();
			for (size_t i=0; i<out_str.size(); i++) {
				if (out_str[i] != ' ') {
					first_valid_char_position = i;
					break;
				}
			}

			int first_trailing_spaces_position = out_str.size();
			for (size_t i=out_str.size()-1; i>=0; i++) {
				if (out_str[i] != ' ') {
					break;
				}
				first_trailing_spaces_position = i;
			}

			// Print out just the characters we need, without the leading and training spaces
			set_position(top_left_x+first_valid_char_position+1, top_left_y+y);
			for (size_t i=first_valid_char_position; i<(size_t)first_trailing_spaces_position; i++) {
				printf("%c", out_str[i]);
			}
		}

		// display slogan and unfade it
		set_position(1, slogan_row);
		set_line_size(6);
		write_centered_large_text(slogan_row, "Power Without the Price", false);
		unfade(slogan_row, slogan_row);

		// set scroll margins to cover fuji logo
		set_scroll_margins(top_left_y, top_left_y+fuji_height-1);

		// Let the pretty colors scroll in and fill the fuji
		for (size_t i=0; i<=0x10e; i+=2) {
			vdelay(5);
			uint8_t color = i;
			// set a new background color. This will be the color scrolled into the bottom line.
			send_sgr({48, 9, color});
			// scroll 1 line, do not scroll_bitmap, do scroll_colors, do not rotate
			colors_vert_scroll_down(1, 0, 1, 0);

			//upper_line_color = color-(fuji_height-1)*2;
		}

		// same as above but fading out shades of gray
		for (int i=0xc; i>=0; i-=2) {
			vdelay(5);
			uint8_t color = i;
			send_sgr({48, 9, color});
			colors_vert_scroll_down(1, 0, 1, 0);
		}

		// let the black color fill the fuji
		for (size_t i=0; i<(size_t)fuji_height; i++) {
			vdelay(5);
			colors_vert_scroll_down(1, 0, 1, 0);
		}

		// fade out the slogan
		fade(slogan_row, slogan_row);
		reset_scroll_margins();
	}

	// phase 3: PM Graphics demo.
	if (true) {
		set_screen_colors({0, 0, 0}); // black screen so the setup is hidden
		vdelay();
		for (int i=0; i<8; i++) {
			set_pm_control(i, 0); // move all players offscreen
		}
		for (int i=0; i<5; i++) {
			pm_fill(i); // clear PM memory
		}
		send_sgr({0, 7}); // reset, then inverse text mode
		clear_screen(); // fills screen with inverse spaces - actually pixels are turned off - needed for seeing PMs!

		// Set entire screen to double width text
		for (int i=1; i<=24; i++) {
			set_position(1, i);
			set_line_size(6);
		}

		// Write header
		int heading_row = 2;
		set_position(1, heading_row);
		write_centered_large_text(heading_row, "The Obligatory Pac Person Demo", false);

		printf("%c", 'N'-64); // ctrl-N, set G1 (graphical) character set
		int graph_top = 8;
		set_position(1,graph_top);
		for (int i=0; i<40; i++) {
			printf("o"); // horizontal bar (upper)
		}
		set_position(40, graph_top+1);
		printf("~"); // dot
		set_position(1,graph_top+2);
		for (int i=0; i<18; i++) {
			printf("q"); // horizontal bar (middle height)
		}
		printf("k  l"); // upper-right and upper-left corner
		for (int i=0; i<18; i++) {
			printf("q");
		}
		for (int y=graph_top+3; y<=24; y++) {
			set_position(19,y);
			printf("x  x"); // vertical bars
		}
		printf("%c", 'O'-64); // ctrl-O, set G0 (normal) character set

		// reveal screen slowly. Reverse colors so screen doesn't look inverse
		for (int i=0; i<=10; i+=2) {
			set_screen_colors({((uint8_t)i), 0, 2}); // reveal screen, reverse colors so screen doesn't look inverse
			vdelay(2);
		}

		vector<vector<uint8_t>> pacman_shapes_rt = { // pacman headed right
			{56,108,254,254,254,124,56},
			{56,108,254,224,254,124,56},
			{56,108,224,192,224,126,56},
			{56,108,254,224,254,124,56} // copy of second shape
		};

		// generate pacman headed left
		vector<vector<uint8_t>> pacman_shapes_lt(pacman_shapes_rt.size());
		for (size_t p=0; p<pacman_shapes_rt.size(); p++) {
			for (size_t i=0; i<pacman_shapes_rt[p].size(); i++) {
				pacman_shapes_lt[p].push_back(flip_bits(pacman_shapes_rt[p][i]));
			}
		}

		vector<vector<uint8_t>> ghost_shapes = {
			{0,60,126,153,187,255,255,255,170,0}, // ghost also moves vertically so add leading and trailing zeros
			{0,60,126,187,153,255,255,255,85,0},
			{0,60,126,221,153,255,255,255,170,0},
			{0,60,126,153,221,255,255,255,85,0}
		};

		const uint8_t pacman_color = 0xfa;
		const uint8_t ghost_normal_color = 0xcc;
		const uint8_t ghost_weak_color = 0x78;

		// prepare pm 0 - pacman
		set_pm_control(0, 0, 0, pacman_color);
		int pacman_shape = 0;

		// prepare pm 1 - ghost
		set_pm_control(1, 0, 0, ghost_normal_color);
		int ghost_shape = 0;

		const uint8_t LEFT_EDGE_PM = 48;
		int frame_num=0;
		const int pacman_y = 46;
		const int ghost_final_y = 44;
		int ghost_x = 76;
		int ghost_y = 103;
		set_pm_control(1, ghost_x+LEFT_EDGE_PM);
		const int GHOST_APPEAR_TIME = 32;
		bool ghost_at_final_y = false;
		// move pacman to the right, while ghost moves up then right
		for (int i=0; i<=160-7; i++) {
			if (frame_num%5 == 0) {
				set_pm_shape(0, pacman_y, pacman_shapes_rt[pacman_shape%4]);
				pacman_shape++;
			}
			set_pm_control(0, i+LEFT_EDGE_PM);
			if (i < GHOST_APPEAR_TIME) {
				// do nothing
			}
			else if (i == GHOST_APPEAR_TIME || frame_num%16 == 0) {
				set_pm_shape(1, ghost_y, ghost_shapes[ghost_shape%4]);
				ghost_shape++;
				if (i == GHOST_APPEAR_TIME) ghost_y--;
			}
			if (i > GHOST_APPEAR_TIME) {
				if (frame_num%16 != 0 && !ghost_at_final_y) {
					pm_vert_move(1, ghost_y+1, ghost_y, ghost_shapes[0].size());
					if (ghost_y == ghost_final_y) {
						ghost_at_final_y = true;
					}
				}
				if (ghost_y > ghost_final_y) {
					ghost_y--;
				}
			}
			if (ghost_at_final_y) {
				set_pm_control(1, ghost_x+LEFT_EDGE_PM);
				ghost_x++;
			}

			vdelay(2);
			frame_num++;
		}

		// erase the dot, color the ghost blue, flip pacman heading
		set_position(40, graph_top+1);
		printf(" ");
		set_pm_control(1, ghost_x+LEFT_EDGE_PM, 0, ghost_weak_color);
		set_pm_shape(0, pacman_y, pacman_shapes_lt[(pacman_shape-1)%4]);

		// now players move to the left
		for (int i=160-9; i>=0; i--) { // start 2 pixels to left of previous position: 1 due to movement, 1 to compensate for
										// the pac-man moving 1 pixel right due to player shape mirroring
			if (frame_num%5 == 0) {
				set_pm_shape(0, pacman_y, pacman_shapes_lt[pacman_shape%4]);
				pacman_shape++;
			}
			if (frame_num%16 == 0) {
				set_pm_shape(1, ghost_y, ghost_shapes[ghost_shape%4]);
				ghost_shape++;
			}
			if (frame_num%25 == 0) {
				i--; // make pacman move just a little faster
			}
			set_pm_control(0, i+LEFT_EDGE_PM);
			ghost_x--;
			set_pm_control(1, ghost_x+LEFT_EDGE_PM);

			vdelay(2);
			frame_num++;

			if (ghost_x <= 0) { // finish when ghost reaches left edge
				break;
			}
		}

		for (int i=0; i<8; i++) {
			set_pm_control(i, 0); // move all players offscreen
		}
		// fade screen to black
		for (int i=10; i>=0; i-=2) {
			set_screen_colors({((uint8_t)i), 0, 2}); // reveal screen, reverse colors so screen doesn't look inverse
			vdelay(2);
		}
		set_screen_colors({0, 0, 0}); // change bordetr to black too
		vdelay(60);
		clear_screen();
	}

	reset_terminal();
	int thatsall_row = 7;
	set_position(1, thatsall_row);
	set_line_size(6);
	write_centered_large_text(thatsall_row, "That's all, folks!", false);
	set_position(1,24);
}
