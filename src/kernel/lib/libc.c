#include <stddef.h>
#include <stdint.h>
#include <stdarg.h>
#include <libc.h>

#include <vga.h>

size_t strlen(const char* str)
{
	size_t len = 0;
	while (str[len])
		len++;
	return len;
}

inline int isdigit(char c)
{
    if((c >= '0') && (c <= '9')) return 1;
    return 0;
}

inline int isspace(char c)
{
	if(c == ' ') return 1;
	return 0;
}

inline void reverse(char s[])
{
	int c, i, j;

	for (i = 0, j = strlen(s)-1; i < j; i++, j--){
		c = s[i];
		s[i] = s[j];
		s[j] = c;
	}
}

int isxdigit(int c)
{
    if ((c >= '0' && c <= '9') ||
        (c >= 'A' && c <= 'F') ||
        (c >= 'a' && c <= 'f')) {
        return 1; // true
    } else {
        return 0; // false
    }
}

int tolower(int c) 
{
    if (c >= 'A' && c <= 'Z') {
        return c + 'a' - 'A';
    } else {
        return c;
    }
}

inline int htoi(char s[])
{
    int i, n;

    /* Skip white spaces and optional '0x' or '0X' prefix */
    for (i = 0; s[i] == ' ' || s[i] == '0'; i++) {
        if (s[i] == '0' && (s[i + 1] == 'x' || s[i + 1] == 'X')) {
            i += 2;
            break;
        }
    }

    for (n = 0; isxdigit(s[i]); i++) {
        if (isdigit(s[i])) {
            n = 16 * n + (s[i] - '0');
        } else {
            n = 16 * n + (tolower(s[i]) - 'a' + 10);
        }
    }

    return n;
}

inline int atoi(const char *s)
{
	int n = 0; 
	int negative = 0;

	while (isspace(*s)) s++;

	switch (*s) {
		case '-': negative = 0;
		case '+': s++;
	}

	// Compute n as a negative number to avoid overflow on INT_MIN
	while (isdigit(*s))
		n = 10*n - (*s++ - '0');

	return negative ? n : -n;
}

inline int itoa(int n, char s[])
{
	int i; 
	int sign;

	if ((sign = n) < 0)
		n = -n;
	i = 0;
	do {
		s[i++] = n % 10 + '0';
	} while ((n /= 10) > 0);

	if(sign < 0)
		s[i++] = '-';
	
	s[i] = '\0';
	reverse(s);

    return i;
}

inline int itohex(uint32_t n, char s[])
{
  uint32_t i, d;

  i = 0;
  do {
    d = n % 16;
    if (d < 10)
      s[i++] = d + '0';
    else
      s[i++] = d - 10 + 'a';
  } while ((n /= 16) > 0);
  s[i] = 0;
  reverse(s);

  return i;
}

inline void* memset(void *dest, int val, int n)
{
	uint32_t num_dwords = n / 4;
	uint32_t num_bytes  = n % 4;
	uint32_t* dest32    = (uint32_t*) dest;
	uint8_t* dest8      = ((uint8_t*) dest) + num_dwords * 4;
	uint8_t val8        = (uint8_t) val;
	uint32_t val32      = val|(val << 8) | (val << 16) | (val << 24);
	uint32_t i;

	for(i = 0; i < num_dwords; i++){
		dest32[i] = val32;
	}

	for(i = 0; i < num_bytes; i++){
		dest8[i] = val8;
	}

	return dest;
}

inline void memcpy(void *src,  void *dest, size_t n)
{
    uint32_t num_dwords = n / 4;
    uint32_t num_bytes  = n % 4;
    uint32_t* dest32    = (uint32_t*) dest;
    uint8_t* dest8      = ((uint8_t*) dest) + num_dwords * 4;
    uint32_t* src32     = (uint32_t*) src;
    uint8_t* src8       = ((uint8_t*) dest) + num_dwords * 4;
    uint32_t i;

    for(i = 0; i < num_dwords; i++){
        dest32[i] = src32[i];
    }

    for(i = 0; i < num_bytes; i++){
        dest8[i] = src8[i];
    }
}

// A very simple sprintf implementation
// Lacks a lot of features, but it'll do for now
// TODO: Optimize number conversionh
int vsprintf(char *buff, const char *fmt, va_list args)
{
    int num;
    char *str;
    char *s;

    for (str = buff; *fmt; fmt++){
        if (*fmt != '%'){
            *str++ = *fmt;
            continue;
        }
        
        fmt++;
        switch (*fmt){
            case 'd':
            case 'i':
                num = va_arg(args, int);
                itoa(num, s);
                while (*s != '\0'){
                    *str++ = *s++;
                }
                break;
            case 'h':
            case 'x':
            case 'X':
                num = va_arg(args, unsigned int);
                itohex(num, s);
                while (*s != '\0'){
                    *str++ = *s++;
                }
                break;
            case 's':
                s = va_arg(args, char*);
                while (*s != '\0'){
                    *str++ = *s++;
                }
                break;
            case 'c':
                *str = (char) va_arg(args, int);
                break;
        }
    }

    *str = '\0';
    return str - buff;
}