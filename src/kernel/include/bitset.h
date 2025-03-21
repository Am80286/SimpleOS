#ifndef BITSET_H
#define BITSET_H

#include <stdint.h>

#define BITS_PER_BLOCK 32 // Using uint32_t as a block

void bitset_set(uint32_t* bitset, uint32_t idx);

void bitset_clear(uint32_t* bitset, uint32_t idx);

uint32_t bitset_test(uint32_t* bitset, uint32_t idx);

#endif