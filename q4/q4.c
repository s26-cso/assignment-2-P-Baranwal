
/*
  Libraries are not known at compile time; each is up to 1.5GB, so only
  one is loaded at a time to keep total memory usage <= 2GB.
 */

#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <dlfcn.h>

#define MAX_OP_LEN 5

// Turns MAX_OP_LEN into a string literal for use in scanf format string 
#define STRINGIFY(x) #x
#define TOSTRING(x)  STRINGIFY(x)

int main() 
{
    char op[MAX_OP_LEN + 1];    // operation name, e.g. "add", "mul" 
    int num1, num2;             // operands read from stdin 

    // Read one operation and two integers per iteration until EOF or bad input 
    while (scanf("%" TOSTRING(MAX_OP_LEN) "s %d %d", op, &num1, &num2) == 3) 
    {
        // Build library path: "./lib<op>.so", e.g. "./libadd.so" 
        char libname[sizeof("./lib") + MAX_OP_LEN + sizeof(".so")];

        strcpy(libname, "./lib");
        strcat(libname, op);
        strcat(libname, ".so");

        // Load the shared library; RTLD_LAZY defers symbol resolution until use 
        void *handle = dlopen(libname, RTLD_LAZY);
        if (!handle) 
        {
            fprintf(stderr, "Error: cannot load library '%s': %s\n", libname, dlerror());
            continue;
        }

        // Clear any existing dlerror state before calling dlsym 
        dlerror();

        // Look up the function symbol matching the operation name 
        int (*func)(int, int) = (int (*)(int, int)) dlsym(handle, op);

        // dlsym can return NULL, so check dlerror to detect failure 
        char *err = dlerror();      
        if (err != NULL) 
        {
            fprintf(stderr, "Error: symbol '%s' not found: %s\n", op, err);
            dlclose(handle);
            continue;
        }

        // Guard against a symbol that resolved to NULL without an error string 
        if (!func) 
        {
            fprintf(stderr, "Error: symbol '%s' resolved to NULL\n", op);
            dlclose(handle);
            continue;
        }

        int result = func(num1, num2);
        printf("%d\n", result);

        // Unload the library to free ~1.5GB before the next iteration 
        dlclose(handle);
    }

}
