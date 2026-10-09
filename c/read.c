// clang -O3 -march=native -msse4.2  read.c -o read  && /usr/bin/time -v ./read

#include <stdio.h>
#include <string.h>

#define BUF_SIZE 65536

int fast_parse_int(char *p) {
    int val = 0, neg = 0;
    if (*p == '-') { neg = 1; p++; }
    while (*p >= '0' && *p <= '9') { val = val * 10 + (*p - '0'); p++; }
    if (*p == '.') {
        p++;
        if (*p >= '0' && *p <= '9') { val = val * 10 + (*p - '0'); p++; }
    }
    return neg ? -val : val;
}

int main() {

    char buf[BUF_SIZE];
    char min_city[128];
    char max_city[128];

    int min = 0;
    int max = 0;
    int total_count = 0;
    size_t leftover = 0;

    FILE *fp = fopen("../out.csv", "rb");

    if (!fp) 
        return 1;

    while (1) {
        // Read into the buffer starting after the leftover data
        size_t n = fread(buf + leftover, 1, BUF_SIZE - leftover, fp);
        
        if (n == 0 && leftover == 0) 
            break;
        
        size_t total = n + leftover;
        char *ptr = buf;
        char *end = buf + total;

        while (ptr < end) {
            char *newline = memchr(ptr, '\n', end - ptr);

            if (!newline) 
                break; 

            char *semi = memchr(ptr, ';', newline - ptr);

            int city_len = semi - ptr;
            int val = fast_parse_int(semi + 1);

            if (val < min) {
                min = val;
                memcpy(min_city, ptr, city_len);
                min_city[city_len] = '\0';
            }

            if (val > max) {
                max = val;
                memcpy(max_city, ptr, city_len);
                max_city[city_len] = '\0';
            }

            total_count++;
            
            ptr = newline + 1;
        }

        leftover = end - ptr;

        if (leftover > 0) {
            memmove(buf, ptr, leftover);
        }
    }

    printf("Min: %.1f (%s)\nMax: %.1f (%s)\nRows: %d\n", 
            (float)min/10.0, min_city, (float)max/10.0, max_city, total_count);

    fclose(fp);
    return 0;
}