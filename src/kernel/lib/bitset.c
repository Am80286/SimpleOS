#include <bitset.h>
#include <stdint.h>

inline void bitset_set(uint32_t* bitset, uint32_t idx)
{
    uint32_t idx_shifted = idx / BITS_PER_BLOCK;
    bitset[idx_shifted] |=  (1) << (idx % BITS_PER_BLOCK);
}

inline void bitset_clear(uint32_t* bitset, uint32_t idx)
{
    uint32_t idx_shifted = idx / BITS_PER_BLOCK;
    bitset[idx_shifted] &=  (1) << ~(idx % BITS_PER_BLOCK);
}

inline uint32_t bitset_test(uint32_t* bitset, uint32_t idx)
{
    uint32_t idx_shifted = idx / BITS_PER_BLOCK;
    return (bitset[idx_shifted] & ( ((1) << (idx % BITS_PER_BLOCK)))) != 0 ;
}