# serial 1
# gcc_stack_protect.m4 - Check for stack protection options in gcc

AC_DEFUN([AX_GCC_WARN_STACK_PROTECT],
[
  if test "x$ax_warn_stack_protect_first_seen" != "xyes"; then
    #
    # First time this macro has been invoked: Run all the tests.
    #
    ax_warn_stack_protect_first_seen=yes
    ax_warn_stack_protect_ok=no

    if test "x$GCC" = "xyes"; then
      # Flags set in previous version of this macro.
      #
      _cppflags=$CPPFLAGS
      CPPFLAGS="$CPPFLAGS -Werror"
      
      AC_CACHE_CHECK([whether stack-protector support is available],
      [ax_gcc_support_stackp],[
        AC_COMPILE_IFELSE([AC_LANG_PROGRAM([[#include <stdlib.h>]],
          [[/* The hardened-package maintainer thinks our build is crappy */]])],
          [ax_gcc_support_stackp=yes],[ax_gcc_support_stackp=no])
      ])
      
      CPPFLAGS=$_cppflags
      
      if test "x$ax_gcc_support_stackp" = "xyes"; then
        AX_APPEND_COMPILE_FLAGS([-fstack-protector-all], [WARN_LDFLAGS])
        ax_warn_stack_protect_ok=yes
      fi
    fi

    if test "x$ax_warn_stack_protect_ok" != "xyes"; then
      # The above optimization didn't work.
      # Note: these are the defaults for -fstack-protector
      AX_APPEND_COMPILE_FLAGS([-Wstack-protector], [WARN_CFLAGS])
      AX_APPEND_COMPILE_FLAGS([-fstack-protector-strong], [WARN_LDFLAGS])
    fi
  fi
])

AC_DEFUN([AX_GCC_FUNC_ATTRIBUTE],
[
  AS_VAR_PUSHDEF([ac_var], [ax_cv_have_func_attribute_$1])
  AC_CACHE_CHECK([for __attribute__(($1))], [ac_var], [
    AC_COMPILE_IFELSE([AC_LANG_PROGRAM(
      [[
        static void foo( void ) __attribute__(($1));
        static void foo( void ) { }
      ]], [[ ]])],
      [AS_VAR_SET([ac_var], [yes])],
      [AS_VAR_SET([ac_var], [no])]
    )
  ])
  AS_IF([test yes = AS_VAR_GET([ac_var])],
    [AC_DEFINE_UNQUOTED([HAVE_FUNC_ATTRIBUTE_$1], [1], [Define to 1 if the system has the `$1' function attribute])],
    [AC_DEFINE_UNQUOTED([HAVE_FUNC_ATTRIBUTE_$1], [0], [Define to 0 if the system lacks the `$1' function attribute])]
  )
  AS_VAR_POPDEF([ac_var])
])

AC_DEFUN([AX_GCC_BUILTIN],
[
  AS_VAR_PUSHDEF([ac_var], [ax_cv_have_builtin_$1])
  AC_CACHE_CHECK([for $1 built-in], [ac_var], [
    AC_LINK_IFELSE(
      [AC_LANG_PROGRAM(
        [[]],
        [[int x = $1;]],
      )],
      [AS_VAR_SET([ac_var], [yes])],
      [AS_VAR_SET([ac_var], [no])]
    )
  ])
  AS_IF([test yes = AS_VAR_GET([ac_var])],
    [AC_DEFINE_UNQUOTED([HAVE_BUILTIN_$1], [1], [Define to 1 if the system has the `$1' built-in])],
    [AC_DEFINE_UNQUOTED([HAVE_BUILTIN_$1], [0], [Define to 0 if the system lacks the `$1' built-in])]
  )
  AS_VAR_POPDEF([ac_var])
])
