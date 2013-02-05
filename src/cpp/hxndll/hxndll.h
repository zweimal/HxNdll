#ifndef HX_NDLL_H
#define HX_NDLL_H

#include <hx/CFFI.h>

#include <boost/typeof/typeof.hpp>
#include <boost/type_traits.hpp>
#include <boost/bind.hpp>
#include <typeinfo>
#include <iostream>

namespace hxndll
{
	template <typename T>
	struct Converter
	{
		static T extract(const value inVal);
		
		static value convert(const T inT);
	};
	
	
	template <>
	struct Converter<value>
	{
		static value extract(const value inVal)
		{
			return inVal;
		}
		
		static value convert(const value inVal)
		{
			return inVal;
		}
	};
	
	template <>
	struct Converter<int>
	{
		static int extract(const value inVal, int inDefault = 0)
		{
			if (val_is_number(inVal))
				return val_number(inVal);
			return inDefault;
		}
		
		static value convert(const int inInt)
		{
			return alloc_int(inInt);
		}
	};
	
	
	template <>
	struct Converter<float>
	{
		static float extract(const value inVal, float inDefault = 0.0)
		{
			if (val_is_number(inVal))
			{
				return val_number(inVal);
			}
			return inDefault;
		}
		
		static value convert(const float inFloat)
		{
			return alloc_float(inFloat);
		}
	};
	
	template <>
	struct Converter<bool>
	{
		static bool extract(const value inVal, bool inDefault = false)
		{
			if (val_is_bool(inVal))
				return val_bool(inVal);
			return inDefault;
		}
		
		static value convert(const bool inBool)
		{
			return alloc_bool(inBool);
		}
	};
	
	template <>
	struct Converter<char *>
	{
		static const char * extract(const value inVal, const char * inDefault = "")
		{
			if (val_is_string(inVal))
				return val_string(inVal);
			if (val_is_object(inVal))
			{
				value __s = val_field(inVal,val_id("__s"));
				if (val_is_string(__s))
					return val_string(__s);
			}
			else if (val_is_object(inVal))
				return val_bool(inVal) ? "true" : "false";
			return inDefault;
		}
		
		static value convert(const char *inStr)
		{
			return alloc_string(inStr);
		}
	};
	
	template <>
	struct Converter<wchar_t *>
	{
		static value convert(const wchar_t *inStr)
		{
			return alloc_wstring(inStr);
		}
	};
	
	template<class T>
	inline value convert(T inObj)
	{
		value ret = Converter<T>::convert(inObj);
		return ret;
	}

	template<class T>
	inline T extract(value inVal) 
	{
		return Converter<T>::extract(inVal); 
	}

	template<class T>
	struct delegate
	{
		template<class F>
		static inline value call(F f)
		{
			T ret = f();
			return convert<T>(ret);
		}
	};

	template<>
	struct delegate<void>
	{
		template<class F>
		static inline value call(F f)
		{
			f();
			return val_null;
		}
	};
	

} // end of namespace hxndll

inline std::ostream& operator << (std::ostream &o, const value &v)
{
	switch( val_type(v) ) 
	{
		case valtNull:
			o << "null";
			break;
		case valtInt:
			o << "int : " << val_int(v);
			break;
		case valtFloat:
			o << "float : ", val_float(v);
			break;
		case valtBool:
			o << "bool : " << (val_bool(v)?"true":"false");
			break;
		case valtArray:
			o << "array : size " << val_array_size(v);
			break;
		case valtFunction:
			o << "function_" << val_fun_nargs(v) << "@" << (void *) v;
			break;
		case valtString:
			o << "string : " << val_string(v) << " (" << val_strlen(v) << "bytes)";
			break;
		case valtAbstractBase:
			o << "abstract of kind " << val_kind(v);
			break;
		case valtObject:
			o << "object@" << (void *) v;
			break;
		case valtEnum:
			o << "enum";
			break;
		case valtClass:
			o << "class@" << (void *) v;
			break;
		default:
			o << "?????";
			break;
		}
	
	return o;
}

#define HXNDLL_DEFINE_PRIM(prim,nparams) \
HXNDLL_PRIM_##nparams(prim) 


#define HXNDLL_PRIM_0(func) \
value func##_fw() \
{ \
	typedef BOOST_TYPEOF(func) ftype; \
	typedef boost::function_traits<ftype> ftraits; \
\
	typedef ftraits::result_type R; \
\
	return hxndll::delegate<R>::call(boost::bind(func)); \
} \
HXNDLL_DEFINE_PRIM_FORWARD(func,0)

#define HXNDLL_PRIM_1(func) \
value func##_fw(value v1) \
{ \
	typedef BOOST_TYPEOF(func) ftype; \
	typedef boost::function_traits<ftype> ftraits; \
\
	typedef ftraits::arg1_type T1; \
	typedef ftraits::result_type R; \
\
	return hxndll::delegate<R>::call(boost::bind(func, hxndll::extract<T1>(v1))); \
}\
HXNDLL_DEFINE_PRIM_FORWARD(func,1)


#define HXNDLL_PRIM_2(func) \
value func##_fw(value v1, value v2) \
{ \
	typedef BOOST_TYPEOF(func) ftype; \
	typedef boost::function_traits<ftype> ftraits; \
\
	typedef ftraits::arg1_type T1; \
	typedef ftraits::arg2_type T2; \
	typedef ftraits::result_type R; \
\
	return hxndll::delegate<R>::call(boost::bind(func, hxndll::extract<T1>(v1), hxndll::extract<T2>(v2))); \
}\
HXNDLL_DEFINE_PRIM_FORWARD(func,2)

#define HXNDLL_PRIM_3(func) \
value func##_fw(value v1, value v2, value v3) \
{ \
	typedef BOOST_TYPEOF(func) ftype; \
	typedef boost::function_traits<ftype> ftraits; \
\
	typedef ftraits::arg1_type T1; \
	typedef ftraits::arg2_type T2; \
	typedef ftraits::arg3_type T3; \
	typedef ftraits::result_type R; \
\
	return hxndll::delegate<R>::call(boost::bind(func, hxndll::extract<T1>(v1), hxndll::extract<T2>(v2), hxndll::extract<T3>(v3))); \
}\
HXNDLL_DEFINE_PRIM_FORWARD(func,3)

#define HXNDLL_PRIM_4(func) \
value func##_fw(value v1, value v2, value v3, value v4) \
{ \
	typedef BOOST_TYPEOF(func) ftype; \
	typedef boost::function_traits<ftype> ftraits; \
\
	typedef ftraits::arg1_type T1; \
	typedef ftraits::arg2_type T2; \
	typedef ftraits::arg3_type T3; \
	typedef ftraits::arg4_type T4; \
	typedef ftraits::result_type R; \
\
	return hxndll::delegate<R>::call( boost::bind( func, hxndll::extract<T1>(v1), hxndll::extract<T2>(v2), \
								hxndll::extract<T3>(v3), hxndll::extract<T4>(v4) ) ); \
}\
HXNDLL_DEFINE_PRIM_FORWARD(func,4)

#define HXNDLL_PRIM_5(func) \
value func##_fw(value v1, value v2, value v3, value v4, value v5) \
{ \
	typedef BOOST_TYPEOF(func) ftype; \
	typedef boost::function_traits<ftype> ftraits; \
\
	typedef ftraits::arg1_type T1; \
	typedef ftraits::arg2_type T2; \
	typedef ftraits::arg3_type T3; \
	typedef ftraits::arg4_type T4; \
	typedef ftraits::arg5_type T5; \
	typedef ftraits::result_type R; \
\
	return hxndll::delegate<R>::call( boost::bind( func, hxndll::extract<T1>(v1), hxndll::extract<T2>(v2), \
								hxndll::extract<T3>(v3), hxndll::extract<T4>(v4), hxndll::extract<T5>(v5) ) ); \
}\
HXNDLL_DEFINE_PRIM_FORWARD(func,5)


#define HXNDLL_PRIM_6(func) \
value func##_fw(value *arg, int count) \
{ \
	typedef BOOST_TYPEOF(func) ftype; \
	typedef boost::function_traits<ftype> ftraits; \
\
	typedef ftraits::arg1_type T1; \
	typedef ftraits::arg2_type T2; \
	typedef ftraits::arg3_type T3; \
	typedef ftraits::arg4_type T4; \
	typedef ftraits::arg5_type T5; \
	typedef ftraits::arg6_type T6; \
	typedef ftraits::result_type R; \
\
	return hxndll::delegate<R>::call( boost::bind( func, hxndll::extract<T1>(arg[0]), hxndll::extract<T2>(arg[1]), \
								hxndll::extract<T3>(arg[2]), hxndll::extract<T4>(arg[3]), hxndll::extract<T5>(arg[4]), \
								hxndll::extract<T6>(arg[5]) ) ); \
} \
HXNDLL_DEFINE_PRIM_FORWARD(func,MULT)

#define HXNDLL_PRIM_7(func) \
value func##_fw(value *arg, int count) \
{ \
	typedef BOOST_TYPEOF(func) ftype; \
	typedef boost::function_traits<ftype> ftraits; \
\
	typedef ftraits::arg1_type T1; \
	typedef ftraits::arg2_type T2; \
	typedef ftraits::arg3_type T3; \
	typedef ftraits::arg4_type T4; \
	typedef ftraits::arg5_type T5; \
	typedef ftraits::arg6_type T6; \
	typedef ftraits::arg7_type T7; \
	typedef ftraits::result_type R; \
\
	return hxndll::delegate<R>::call( boost::bind( func, hxndll::extract<T1>(arg[0]), hxndll::extract<T2>(arg[1]), \
								hxndll::extract<T3>(arg[2]), hxndll::extract<T4>(arg[3]), hxndll::extract<T5>(arg[4]), \
								hxndll::extract<T6>(arg[5]), hxndll::extract<T7>(arg[6]) ) ); \
} \
HXNDLL_DEFINE_PRIM_FORWARD(func,MULT)

#define HXNDLL_PRIM_8(func) \
value func##_fw(value *arg, int count) \
{ \
	typedef BOOST_TYPEOF(func) ftype; \
	typedef boost::function_traits<ftype> ftraits; \
\
	typedef ftraits::arg1_type T1; \
	typedef ftraits::arg2_type T2; \
	typedef ftraits::arg3_type T3; \
	typedef ftraits::arg4_type T4; \
	typedef ftraits::arg5_type T5; \
	typedef ftraits::arg6_type T6; \
	typedef ftraits::arg7_type T7; \
	typedef ftraits::arg8_type T8; \
	typedef ftraits::result_type R; \
\
	return hxndll::delegate<R>::call( boost::bind( func, hxndll::extract<T1>(arg[0]), hxndll::extract<T2>(arg[1]), \
								hxndll::extract<T3>(arg[2]), hxndll::extract<T4>(arg[3]), hxndll::extract<T5>(arg[4]), \
								hxndll::extract<T6>(arg[5]), hxndll::extract<T7>(arg[6]), hxndll::extract<T8>(arg[7]) ) ); \
} \
HXNDLL_DEFINE_PRIM_FORWARD(func,MULT)

#define HXNDLL_PRIM_9(func) \
value func##_fw(value *arg, int count) \
{ \
	typedef BOOST_TYPEOF(func) ftype; \
	typedef boost::function_traits<ftype> ftraits; \
\
	typedef ftraits::arg1_type T1; \
	typedef ftraits::arg2_type T2; \
	typedef ftraits::arg3_type T3; \
	typedef ftraits::arg4_type T4; \
	typedef ftraits::arg5_type T5; \
	typedef ftraits::arg6_type T6; \
	typedef ftraits::arg7_type T7; \
	typedef ftraits::arg8_type T8; \
	typedef ftraits::arg9_type T9; \
	typedef ftraits::result_type R; \
\
	return hxndll::delegate<R>::call( boost::bind( func, hxndll::extract<T1>(arg[0]), hxndll::extract<T2>(arg[1]), \
								hxndll::extract<T3>(arg[2]), hxndll::extract<T4>(arg[3]), hxndll::extract<T5>(arg[4]), \
								hxndll::extract<T6>(arg[5]), hxndll::extract<T7>(arg[6]), hxndll::extract<T8>(arg[7]), \
								hxndll::extract<T9>(arg[8])) ); \
} \
HXNDLL_DEFINE_PRIM_FORWARD(func,MULT)

#ifdef STATIC_LINK

#define HXNDLL_DEFINE_PRIM_FORWARD(func,nargs) \
int __reg_##func = hx_register_prim(#func "__" #nargs,(void *)(&func##_fw));

#else

#define HXNDLL_DEFINE_PRIM_FORWARD(func,nargs) extern "C" { \
  EXPORT void *func##__##nargs() { return (void*)(&func##_fw); } \
}

#endif // !STATIC_LINK

#endif
