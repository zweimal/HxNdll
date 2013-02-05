#define NEKO_COMPATIBLE
#define IMPLEMENT_API

#include "hxndll.h"

inline int wrapper_sample_sum(int a, int b)
{
    return a + b;
}
HXNDLL_DEFINE_PRIM( wrapper_sample_sum, 2 );

inline int wrapper_sample_sum7(int a1, int a2, int a3, int a4, int a5, int a6, int a7)
{
    return a1 + a2 + a3 + a4 + a5 + a6 + a7;
}
HXNDLL_DEFINE_PRIM( wrapper_sample_sum7, 7 );

inline void wrapper_sample_void_func(value self, float b)
{
    std::cout << "hx obj: " << self << " float: " << b << std::endl;
}
HXNDLL_DEFINE_PRIM( wrapper_sample_void_func, 2 );

