#ifndef __LIBC_H
#define __LIBC_H

#include <stdint.h>
#include <stddef.h>
#include <stdarg.h>

size_t strlen(const char* str);

int isdigit(char c);

int isspace(char c);

void reverse(char s[]);

int isxdigit(int c);

int tolower(int c);

int htoi(char s[]);

int atoi(const char *s);

int itoa(int n, char s[]);

int itohex(uint32_t n, char s[]);

void* memset(void *dest, int val, int n);

int vsprintf(char *buff, const char *fmt, va_list args);

#endif