#define _GNU_SOURCE
#include <dirent.h>
#include <dlfcn.h>
#include <stddef.h>
int scandir64(const char *dir, struct dirent64 ***list, int (*filter)(const struct dirent64 *), int (*compar)(const struct dirent64 **, const struct dirent64 **)) {
    static int (*real_fn)(const char *,struct dirent64 ***,int (*)(const struct dirent64 *),int (*)(const struct dirent64 **,const struct dirent64 **));
    if (!real_fn) real_fn=dlsym(RTLD_NEXT,"scandir64");
    *list=NULL;
    return real_fn(dir,list,filter,compar);
}
