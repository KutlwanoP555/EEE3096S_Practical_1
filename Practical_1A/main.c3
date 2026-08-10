
/* USER CODE BEGIN Header /
/*

@file           : main.c

@brief          : Task 2 - Running light with debounced speed toggle

/
/ USER CODE END Header */

/* Includes ------------------------------------------------------------------*/
#include "main.h"
#include "stm32f0xx.h"
#include <stdint.h>


/* Private variables ---------------------------------------------------------*/
TIM_HandleTypeDef htim16;

/* USER CODE BEGIN PV */
volatile uint8_t timer_event = 0;
volatile uint8_t current_led = 0;
volatile int8_t direction = 1;

// LED arrays
GPIO_TypeDef* led_ports[8] = {GPIOB, GPIOB, GPIOB, GPIOB,
GPIOB, GPIOB, GPIOB, GPIOB};
uint16_t led_pins[8] = {GPIO_PIN_0, GPIO_PIN_1, GPIO_PIN_2, GPIO_PIN_3,
GPIO_PIN_4, GPIO_PIN_5, GPIO_PIN_6, GPIO_PIN_7};

// TODO: Define your debounce delay based on your oscilloscope measurement
// measure oscilloscpe
#define DEBOUNCE_MS 5 // should meare

uint32_t last_button_press_time = 0;  // might want to make volatile
// Speed state: 0 = slow (1s), 1 = fast (0.5s)
uint8_t speed_state = 0;

// Current ARR value (stored for reference)
uint32_t current_arr = 999;
/* USER CODE END PV */

/* Private function prototypes -----------------------------------------------*/
void SystemClock_Config(void);
static void MX_GPIO_Init(void);
static void MX_TIM16_Init(void);
void TIM16_IRQHandler(void);
void turn_off_all_leds(void);
void update_led_pattern(void);
void handle_button_press(void);
void change_timer_period(uint32_t new_period_ms);

/* USER CODE BEGIN 0 */
void turn_off_all_leds(void)
{
// TODO: Iterate through the LED array. Set all pins to GPIO_PIN_RESET.
	for(int i = 0;i<8 ; i++){
		HAL_GPIO_WritePin(GPIOB, led_pins[i], GPIO_PIN_RESET);
	}

}

void update_led_pattern(void)
{
// TODO: Turn off all LEDs.
	turn_off_all_leds();
// TODO: Turn on the specific LED at index 'current_led'.
	HAL_GPIO_WritePin(GPIOB, led_pins[current_led], GPIO_PIN_SET);
// TODO: Increment or decrement 'current_led' based on 'direction'.
	if (direction == 1) // foward
	{current_led++;}
	else
	{current_led--;}// Reverse
// TODO: Reverse 'direction' when reaching the ends (0 or 7).
	if(current_led == 7)
	{direction = 0;} // turn back
	else if(current_led == 0)
	{direction = 1;} // forward again
}

void change_timer_period(uint32_t new_period_ms)
{
// TODO: Calculate the new ARR value using your formula.
// Note: Timer clock is 1000 Hz (Prescaler is 7999).
uint32_t new_arr = 0; 
	new_arr = ((new_period_ms* 1000)/(8000))-1;

// TODO: Update the TIM16 ARR register directly.
	TIM16->ARR = new_arr;

// TODO: Reset the TIM16 CNT register to 0.
	TIM16->CNT = 0;
// Store the new ARR value for reference
current_arr = new_arr;
}

void handle_button_press(void)
{
// TODO: Get the current system tick using HAL_GetTick().
	uint32_t now = HAL_GetTick();
// TODO: Check the time elapsed since the last valid press.
// Compare the elapsed time against DEBOUNCE_MS.
	uint32_t elapsed = now - last_button_press_time;
	volatile uint8_t isValid = 0 ; // bool

	if (elapsed > DEBOUNCE_MS)
	{isValid = 1;}
	else
	{isValid = 0;}

// TODO: Read the PA0 button state. The button is active low.
	GPIO_PinState button = HAL_GPIO_ReadPin(GPIOA, GPIO_PIN_0);
	uint8_t pressedButton = (button == GPIO_PIN_RESET);
// TODO: If a valid debounced press occurs:
	if(isValid && pressedButton)
	{
// 1. Update last_button_press_time.
	last_button_press_time = now;
// 2. Toggle speed_state between 0 and 1.
	speed_state = !speed_state;
// 3. Call change_timer_period() with 500 or 1000.
	if(speed_state == 1)
	{change_timer_period(500);}
	else
	{change_timer_period(1000);}


	}

}
/* USER CODE END 0 */

/*

@brief  The application entry point.

@retval int
*/
int main(void)
{
HAL_Init();
SystemClock_Config();

MX_GPIO_Init();
MX_TIM16_Init();

/* USER CODE BEGIN 2 */
turn_off_all_leds();

// Start timer at 1-second period
change_timer_period(1000);
HAL_TIM_Base_Start_IT(&htim16);
/* USER CODE END 2 */

while (1)
{
/* USER CODE BEGIN WHILE */
// Handle button press (debounced)
handle_button_press();

// Handle timer event
if (timer_event) {
  timer_event = 0;
  update_led_pattern();
}
/* USER CODE END WHILE */
}
}

/*

@brief System Clock Configuration (HSI 8 MHz)
*/
void SystemClock_Config(void)
{
LL_FLASH_SetLatency(LL_FLASH_LATENCY_0);
while(LL_FLASH_GetLatency() != LL_FLASH_LATENCY_0) {}

LL_RCC_HSI_Enable();
while(LL_RCC_HSI_IsReady() != 1) {}

LL_RCC_HSI_SetCalibTrimming(16);
LL_RCC_SetAHBPrescaler(LL_RCC_SYSCLK_DIV_1);
LL_RCC_SetAPB1Prescaler(LL_RCC_APB1_DIV_1);
LL_RCC_SetSysClkSource(LL_RCC_SYS_CLKSOURCE_HSI);
while(LL_RCC_GetSysClkSource() != LL_RCC_SYS_CLKSOURCE_STATUS_HSI) {}

LL_SetSystemCoreClock(8000000);
if (HAL_InitTick(TICK_INT_PRIORITY) != HAL_OK) {
Error_Handler();
}
}

/*

@brief TIM16 Initialization - Prescaler fixed at 7999
*/
static void MX_TIM16_Init(void)
{
htim16.Instance = TIM16;
htim16.Init.Prescaler = 7999;
htim16.Init.CounterMode = TIM_COUNTERMODE_UP;
htim16.Init.Period = 999;
htim16.Init.ClockDivision = TIM_CLOCKDIVISION_DIV1;
htim16.Init.RepetitionCounter = 0;
htim16.Init.AutoReloadPreload = TIM_AUTORELOAD_PRELOAD_ENABLE;
if (HAL_TIM_Base_Init(&htim16) != HAL_OK) {
Error_Handler();
}
NVIC_EnableIRQ(TIM16_IRQn);
}

/*

@brief GPIO Initialization - PB0..PB7 as outputs, PA0 as input with pull-up
*/
static void MX_GPIO_Init(void)
{
__HAL_RCC_GPIOA_CLK_ENABLE();
__HAL_RCC_GPIOB_CLK_ENABLE();

GPIO_InitTypeDef GPIO_InitStruct = {0};

// Configure LEDs (PB0..PB7) as outputs
GPIO_InitStruct.Mode = GPIO_MODE_OUTPUT_PP;
GPIO_InitStruct.Pull = GPIO_NOPULL;
GPIO_InitStruct.Speed = GPIO_SPEED_FREQ_LOW;

for (uint8_t i = 0; i < 8; i++) {
GPIO_InitStruct.Pin = led_pins[i];
HAL_GPIO_Init(led_ports[i], &GPIO_InitStruct);
}

// Configure PA0 as input with pull-up (button active low)
GPIO_InitStruct.Pin = GPIO_PIN_0;
GPIO_InitStruct.Mode = GPIO_MODE_INPUT;
GPIO_InitStruct.Pull = GPIO_PULLUP;
HAL_GPIO_Init(GPIOA, &GPIO_InitStruct);
}

/*

@brief TIM16 interrupt handler - sets flag only
*/
void TIM16_IRQHandler(void)
{
HAL_TIM_IRQHandler(&htim16);
timer_event = 1;
}

/*

@brief Error handler
*/
void Error_Handler(void)
{
__disable_irq();
while (1) {}
}
