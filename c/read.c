// clang -O3 -march=native -msse4.2  read.c -o read.o  && /usr/bin/time -v ./read.o

#include <stdio.h>
#include <stdlib.h>
#include <string.h>

#define BUF_SIZE 65536 

static inline int fast_parse_int(char *p, char **next) {
    int val = 0, neg = 0;
    if (*p == '-') { neg = 1; p++; }
    while (*p >= '0' && *p <= '9') { val = val * 10 + (*p - '0'); p++; }
    if (*p == '.') {
        p++;
        if (*p >= '0' && *p <= '9') { val = val * 10 + (*p - '0'); p++; }
    }
    if (next) *next = p;
    return neg ? -val : val;
}

int main() {

    FILE *fp = fopen("../out.csv", "rb");

    if (!fp) 
        return 1;

    char *buf = malloc(BUF_SIZE);
    int final_min = 2147483647, final_max = -2147483647;
    char min_city[128], max_city[128];
    int total_count = 0;
    size_t leftover = 0;

    while (1) {
        size_t n = fread(buf + leftover, 1, BUF_SIZE - leftover, fp);
        if (n == 0 && leftover == 0) break;
        
        size_t total = n + leftover;
        char *ptr = buf;
        char *end = buf + total;

        while (ptr < end) {
            char *line_end = memchr(ptr, '\n', end - ptr);
            if (!line_end) break; // Incomplete line, wait for next read

            char *sep = memchr(ptr, ';', line_end - ptr);
            if (sep) {
                int city_len = (int)(sep - ptr);
                int val = fast_parse_int(sep + 1, NULL);

                if (val < final_min) {
                    final_min = val;
                    memcpy(min_city, ptr, city_len);
                    min_city[city_len] = '\0';
                }
                if (val > final_max) {
                    final_max = val;
                    memcpy(max_city, ptr, city_len);
                    max_city[city_len] = '\0';
                }
                total_count++;
            }
            ptr = line_end + 1;
        }

        leftover = end - ptr;
        memmove(buf, ptr, leftover);
    }

    printf("Min: %.1f (%s)\nMax: %.1f (%s)\nRows: %d\n", 
           (float)final_min/10.0, min_city, (float)final_max/10.0, max_city, total_count);

    free(buf);
    fclose(fp);
    return 0;
}