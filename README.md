# Kria_FileSystem_prj

Repository to configurate Arch-A development with FreeRTOS using FileSystem and Command Promp


<img src="image/README/1704944064750.png" alt="1704944064750" height="200"/>

<img src="image/README/1704944071318.png" alt="1704944071318" width="400"/>

# Vidado_HOG_example

Proyecto temporal para mirar la integracion con HOG

Para correr Vivado desde consola primero se debe correr el siguiente comando en la terminal

```bash
$env:PATH += ";D:\Xilinx\Vivado\2022.2\bin"
```

### Recomiendo trabajar con Git Bash

En git bash

```bash
export PATH="/d/Xilinx/Vivado/2022.2/bin:$PATH"
```

Para clonar el repositorio con exito y sin errores usar la siguiente linea

```bash
git clone -b devFabian --recurse-submodules https://github.com/fabioc9675/Kria_FileSystem_prj.git
```

Con `--recurse-submodules` se garantiza que se clonan los submodulos completos, y con `-b devFabian` es para clonar el branch en el que estoy trabajando con el modulo HOG,

### Inicializacion de HOG

para convertir proyecto existente en HOG utiliza la siguiente linea

```bash
./Hog/Init.sh
```

Con esto se escanearan los proyectos existentes y Hog creara un directorio `Top` donde estaran listados los proyectos existentes (`<mark>probar<\mark>)`

Luego crearemos el proyecto con la linea:

```bash
./Hog/Do CREATE Kria_freertos
```

`project_hog` es el nombre que le dimos al proyecto inicialmente, entonces ahi se pone el nombre del proyecto que se este creando

---

Create by: Fabian Castaño
