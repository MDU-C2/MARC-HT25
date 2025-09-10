#include <stdio.h>

void PrintHelloWorld(char* input_string);

#define MACRO_EXAMPLE 0

/* Global variabels names have the same structure as a function.
   Also, constants start with k. */
const char kThisIsAGlobalVariable[] = "Hello";

/// @brief Run once and prints "Hello World" to terminal
/// @return returns 0 if valid run
int main(void)
{
    // start with small letter -> local variable
    char this_is_a_local_variable[] = "World";

    PrintHelloWorld(this_is_a_local_variable);

    return 0;
}

/// @brief This function prints "Hello" inputstring
/// @param input_string input string is a char pointer that prints after "hello"
void PrintHelloWorld(const char* kinput_string)
{
    printf("%s %s\n",kThisIsAGlobalVariable,kinput_string); // prints to terminal
}