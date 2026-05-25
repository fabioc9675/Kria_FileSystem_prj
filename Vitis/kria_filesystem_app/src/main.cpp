#include "FreeRTOS.h"
#include "task.h"
#include "xil_printf.h"
#include "xsdps_hw.h" // Cabecera de registros nativos de la SD
#include <cstdio>  // <-- ¡ESTE ES EL QUE FALTA para snprintf!
#include <cstring> // Para strlen y memset si los usas

// Forzamos al compilador de C++ a mantener los nombres limpios de FatFs
extern "C" {
#include "ff.h"
}

static FATFS fatfs;

void vSDTask(void *pvParameters) {
	FIL fil;          // Objeto de archivo
	FIL fil1;          // Objeto de archivo
	FIL fil2;          // Objeto de archivo
	FRESULT res;      // Resultado de operaciones
	char buffer[2048] = { 0 }; // Buffer para leer
	UINT bw;                // Bytes escritos
	UINT br;                // Bytes leídos

	// Usa UINTPTR que es el tipo nativo de Xilinx para direcciones de 64/32 bits
	UINTPTR base_addr = XPAR_PSU_SD_1_BASEADDR;

	// Forzar el encendido del bus: 3.3V (0x0E) + Bus Power On (0x01) = 0x0F
	XSdPs_WriteReg8(base_addr, XSDPS_POWER_CTRL_OFFSET, 0x0F);

	// Delay corto de FreeRTOS para que el silicio asiente la configuración
	vTaskDelay(pdMS_TO_TICKS(10));

	xil_printf("Montando SD..\r\n");

	// Montar la unidad 0 (SD1 mapeada en hardware)
	res = f_mount(&fatfs, "0:/", 1);
	if (res != FR_OK) {
		xil_printf("Error montando SD: %d\r\n", res);
		vTaskDelete(NULL);
	}

	// ============================================================================
	// PASO 2: CREAR UN ARCHIVO NUEVO Y ESCRIBIR DATOS INITIALES
	// ============================================================================
	xil_printf("1. Creando archivo 'ejemplo.txt'...\r\n");
	// FA_CREATE_ALWAYS: Crea el archivo. Si ya existe, lo sobrescribe desde cero.
	res = f_open(&fil, "ejemplo.txt", FA_WRITE | FA_CREATE_ALWAYS);
	if (res != FR_OK) {
		xil_printf("Error al crear archivo: %d\r\n", res);
	}

	const char *texto_inicial =
			"Linea 1: Datos iniciales desde el Core 1 (FreeRTOS).\r\n";
	xil_printf("Escribiendo datos iniciales...\r\n");
	res = f_write(&fil, texto_inicial, strlen(texto_inicial), &bw);
	if (res != FR_OK || bw != strlen(texto_inicial)) {
		xil_printf("Error al escribir iniciales: %d (bytes escritos: %d)\r\n",
				res, bw);
		f_close(&fil);
	}

	// Es vital cerrar el archivo para asegurar que los datos se guarden físicamente
	f_close(&fil);
	vTaskDelay(pdMS_TO_TICKS(100));

	for (int i = 0; i < 20; i++) {

		vTaskDelay(100);

		xil_printf("Abriendo Prueba.txt...\r\n");
		res = f_open(&fil1, "Prueba.txt", FA_READ);
		if (res != FR_OK) {
			xil_printf("No se encontro el archivo. Error: %d\r\n", res);
			//vTaskDelete(NULL);
		}

		xil_printf("Leyendo contenido:\r\n---\r\n");
		f_read(&fil1, buffer, sizeof(buffer) - 1, &br);
		buffer[br] = '\0'; // Asegura fin de cadena
		xil_printf("%s\r\n---\r\n", buffer);

		f_close(&fil1);

		vTaskDelay(100);

		xil_printf("Abriendo Texto.txt...\r\n");
		res = f_open(&fil2, "Texto.txt", FA_READ);
		if (res != FR_OK) {
			xil_printf("No se encontro el archivo. Error: %d\r\n", res);
			//vTaskDelete(NULL);
		}

		xil_printf("Leyendo contenido:\r\n---\r\n");
		f_read(&fil2, buffer, sizeof(buffer) - 1, &br);
		buffer[br] = '\0'; // Asegura fin de cadena
		xil_printf("%s\r\n---\r\n", buffer);

		f_close(&fil2);

		// ============================================================================
		// PASO 3: HACER APPEND (AÑADIR DATOS AL FINAL)
		// ============================================================================
		xil_printf("\r\n2. Abriendo archivo para hacer APPEND...\r\n");
		// Abrimos con FA_WRITE y FA_OPEN_ALWAYS (abre si existe, lo crea si no)
		res = f_open(&fil, "ejemplo.txt", FA_WRITE | FA_OPEN_ALWAYS);
		if (res != FR_OK) {
			xil_printf("Error al abrir para append: %d\r\n", res);
		}

		// El truco del APPEND: Mover el puntero del archivo al tamaño total del archivo
		xil_printf("Moviendo puntero al final del archivo (Append)...\r\n");
		res = f_lseek(&fil, f_size(&fil));
		if (res != FR_OK) {
			xil_printf("Error en f_lseek: %d\r\n", res);
			f_close(&fil);
		}

		char linea_dinamica[100];
		snprintf(linea_dinamica, sizeof(linea_dinamica),
		         "Linea %d: Estos datos se agregaron con APPEND exitosamente.\r\n", i);

		// 3. Pasas el buffer formateado a la función de FatFs
		res = f_write(&fil, linea_dinamica, strlen(linea_dinamica), &bw);
		if (res != FR_OK || bw != strlen(linea_dinamica)) {
		    xil_printf("Error al hacer append en iteracion %d: %d\r\n", i, res);
		    f_close(&fil);
		}

		f_close(&fil);
		vTaskDelay(pdMS_TO_TICKS(100));

		// ============================================================================
		// PASO 4: LEER EL ARCHIVO COMPLETO PARA VERIFICAR
		// ============================================================================
		xil_printf(
				"\r\n3. Abriendo archivo para LEER el resultado final...\r\n");
		res = f_open(&fil, "ejemplo.txt", FA_READ);
		if (res != FR_OK) {
			xil_printf("Error al abrir para lectura: %d\r\n", res);
		}

		xil_printf(
				"Leyendo contenido completo:\r\n---------------------------------------\r\n");
		memset(buffer, 0, sizeof(buffer)); // Limpiamos buffer
		res = f_read(&fil, buffer, sizeof(buffer) - 1, &br);
		if (res == FR_OK) {
			buffer[br] = '\0'; // Asegurar terminación de string
			xil_printf("%s", buffer);
			xil_printf("---------------------------------------\r\n");
			xil_printf("Bytes leidos con exito: %d\r\n", br);
		} else {
			xil_printf("Error al leer: %d\r\n", res);
		}

		f_close(&fil);

		vTaskDelay(1000);
	}

	f_mount(NULL, "0:/", 0);

	xil_printf("Ejemplo terminado.\r\n---------------------------------------\r\n");

	vTaskDelete(NULL);
}

int main() {

	xTaskCreate(vSDTask, "SDTask", 4096, NULL, tskIDLE_PRIORITY + 1, NULL);
	vTaskStartScheduler();
	while (1)
		;
	return 0;
}
