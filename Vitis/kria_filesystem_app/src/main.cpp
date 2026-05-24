#include "FreeRTOS.h"
#include "task.h"
#include "xil_printf.h"
#include "xsdps_hw.h" // Cabecera de registros nativos de la SD


// Forzamos al compilador de C++ a mantener los nombres limpios de FatFs
extern "C" {
    #include "ff.h"
}

static FATFS fatfs;

void vSDTask(void *pvParameters)
{
    FIL fil;          // Objeto de archivo
    FRESULT res;      // Resultado de operaciones
    char buffer[100] = {0}; // Buffer para leer
    UINT br;          // Bytes leidos

    // Usa UINTPTR que es el tipo nativo de Xilinx para direcciones de 64/32 bits
    UINTPTR base_addr = XPAR_PSU_SD_1_BASEADDR;

    // Forzar el encendido del bus: 3.3V (0x0E) + Bus Power On (0x01) = 0x0F
    XSdPs_WriteReg8(base_addr, XSDPS_POWER_CTRL_OFFSET, 0x0F);

    // Delay corto de FreeRTOS para que el silicio asiente la configuración
    vTaskDelay(pdMS_TO_TICKS(10));

    xil_printf("Montando SD..\r\n");

    // Montar la unidad 0 (SD1 mapeada en hardware)
    res = f_mount(&fatfs, "0:/", 1);
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
