#include "FreeRTOS.h"
#include "task.h"
#include "ff.h"
#include "xil_printf.h"

static FATFS fatfs;

void vSDTask(void *pvParameters)
{
    FIL fil;          // Objeto de archivo
    FRESULT res;      // Resultado de operaciones
    char buffer[100]; // Buffer para leer
    UINT br;          // Bytes leidos

    xil_printf("Montando SD..\r\n");

    // Montar la unidad 0 (SD1 mapeada en hardware)
    res = f_mount(&fatfs, "1:/", 1);
    if (res != FR_OK)
    {
        xil_printf("Error montando SD: %d\r\n", res);
        vTaskDelete(NULL);
    }

    xil_printf("Abriendo prueba.txt...\r\n");
    res = f_open(&fil, "prueba.txt", FA_READ);
    if (res != FR_OK)
    {
        xil_printf("No se encontro el archivo. Error: %d\r\n", res);
        vTaskDelete(NULL);
    }

    xil_printf("Leyendo contenido:\r\n---\r\n");
    f_read(&fil, buffer, sizeof(buffer)-1, &br);
    buffer[br] = '\0'; // Asegura fin de cadena
    xil_printf("%s\r\n---\r\n", buffer);

    f_close(&fil);
    f_mount(NULL, "0:/", 0);
    xil_printf("Prueba finalizada.\r\n");

    vTaskDelete(NULL);
}

int main()
{

xTaskCreate(vSDTask, "SDTask", 4096, NULL, tskIDLE_PRIORITY + 1, NULL);
    vTaskStartScheduler();
    while(1);
    return 0;
}
