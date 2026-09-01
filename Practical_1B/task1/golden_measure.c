/*
 * Task 1: The Golden Measure on the PC
 *
 * Integer square root of a 32-bit unsigned input x: the largest integer
 * whose square does not exceed x.  Golden version uses double precision
 * arithmetic and the standard library square root.
 *
 * Build:   gcc -O2 -o golden_measure golden_measure.c -lm
 * Run:     ./golden_measure
 */

#include <stdio.h>
#include <stdint.h>
#include <inttypes.h>
#include <math.h>
#include <time.h>

static const uint32_t inputs[10] = {
    0, 1, 15, 16, 4095, 65535,
    123456789, 987654321, 4294836225u, 4294967295u
};

/*
 * Golden integer square root.
 * sqrt on a double can return a value a hair below the true root for a
 * perfect square, so floor would give an answer one too low.  We floor,
 * then nudge across the exact boundary using 64-bit squaring so the
 * comparison never overflows.
 */
static uint32_t golden_isqrt(uint32_t x)
{
    uint32_t r = (uint32_t)floor(sqrt((double)x));

    while (r > 0u && (uint64_t)r * r > x) {
        r--;
    }
    while ((uint64_t)(r + 1u) * (r + 1u) <= x) {
        r++;
    }
    return r;
}

/* Returns the current time in microseconds using the monotonic clock. */
static double timestamp_us(void)
{
    struct timespec ts;
    clock_gettime(CLOCK_MONOTONIC, &ts);
    return (double)ts.tv_sec * 1e6 + (double)ts.tv_nsec / 1e3;
}

/* Hand check: r^2 <= x < (r+1)^2, written out in full. */
static int hand_check(uint32_t x, uint32_t r)
{
    uint64_t r_sq       = (uint64_t)r * r;
    uint64_t r_plus1_sq = (uint64_t)(r + 1u) * (r + 1u);

    int lower_ok = (r_sq <= x);
    int upper_ok = (r_plus1_sq > x);

    return (lower_ok && upper_ok);
}

/*
 * Times reps calls to golden_isqrt and returns the mean time per call in
 * microseconds.  A volatile sink stops the optimiser deleting the loop.
 */
static double time_n_calls(long reps)
{
    volatile uint32_t sink = 0;
    double start = timestamp_us();

    for (long i = 0; i < reps; i++) {
        sink = golden_isqrt(987654321u);
    }

    double end = timestamp_us();
    (void)sink;

    return (end - start) / (double)reps;
}

int main(void)
{
    /* --- Output table for the ten inputs --- */
    printf("  input         golden isqrt   hand-check\n");
    printf("  ------------  ------------   ----------\n");
    for (int i = 0; i < 10; i++) {
        uint32_t r = golden_isqrt(inputs[i]);
        printf("  %-12" PRIu32 "  %-12" PRIu32 "   %s\n",
               inputs[i], r, hand_check(inputs[i], r) ? "OK" : "FAIL");
    }

    /* --- One hand-check written out in full (perfect square) --- */
    {
        uint32_t x = 4294836225u;              /* 65535^2 */
        uint32_t r = golden_isqrt(x);
        printf("\nHand-check for x = %" PRIu32 ":\n", x);
        printf("  r          = %" PRIu32 "\n", r);
        printf("  r^2        = %" PRIu64 "  (<= x? %s)\n",
               (uint64_t)r * r, ((uint64_t)r * r <= x) ? "yes" : "no");
        printf("  (r+1)^2    = %" PRIu64 "  (>  x? %s)\n",
               (uint64_t)(r + 1u) * (r + 1u),
               ((uint64_t)(r + 1u) * (r + 1u) > x) ? "yes" : "no");
    }

    /* --- Timing: two runs with different repetition counts --- */
    long reps1 = 1000000;
    long reps2 = 5000000;
    double t1 = time_n_calls(reps1);
    double t2 = time_n_calls(reps2);

    printf("\nTiming (input 987654321):\n");
    printf("  run 1: %ld reps, %.4f us/call\n", reps1, t1);
    printf("  run 2: %ld reps, %.4f us/call\n", reps2, t2);
    printf("  mean : %.4f us/call, spread: %.4f us\n",
           (t1 + t2) / 2.0, (t1 > t2) ? (t1 - t2) : (t2 - t1));

    return 0;
}