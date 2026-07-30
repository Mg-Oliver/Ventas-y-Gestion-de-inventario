# OvniCore Inventario - Sistema de Gestión de Inventario y Ensamble de Hardware

OvniCore Inventario es una solución empresarial desarrollada en Flutter y Firebase diseñada para la administración, trazabilidad, control financiero y ensamble inteligente de componentes informáticos y periféricos de tecnología.

---

## Características Principales

### 1. Gestión de Inventarios y Componentes
- **Hardware Interno**: Control detallado para Procesadores (CPU), Tarjetas Madres, Memorias RAM (DDR, DDR2, DDR3, DDR4, DDR5), Almacenamiento (SSD, HDD, NVMe M.2), Tarjetas Gráficas (GPU), Fuentes de Poder (PSU), Gabinetes, Disipadores y Ventiladores de Chasís.
- **Periféricos Externos**: Registro técnico para Monitores, Teclados (Mecánicos, Ópticos, Magnéticos Efecto Hall), Mouses (DPI, modelos de sensor optico), Audífonos y Altavoces con conectividades múltiples (Bluetooth, 2.4GHz, USB, Jack 3.5mm).
- **Control de Activos**: Generación automática de identificadores únicos secuenciales por categoría.
- **Registro de Compras**: Soporte para registro de compras convencionales y opción directa de adquisición por donación / regalo ($0.00 USD).

### 2. Motor de Compatibilidad Automática
- Evaluación en tiempo real de compatibilidad técnica entre piezas:
  - Coincidencia de Sockets de Procesador vs. Tarjeta Madre.
  - Coincidencia de tecnología de Memoria RAM soportada.
  - Compatibilidad de Sockets y altura física de Disipadores de CPU.
  - Dimensiones físicas de Tarjetas Gráficas vs. capacidad del Gabinete.
  - Factores de Forma de Tarjetas Madres (ATX, Micro-ATX, Mini-ITX) vs. soporte de Chasís.
  - Consumo total estimado en Watts vs. potencia máxima de la Fuente de Poder.
- Detección interactiva de compatibilidades en stock desde la ficha de cada componente.

### 3. Armador de PC (PC Builder)
- Simulador de ensamble de computadoras organizado por componentes estilo PCPartPicker.
- Filtro en tiempo real que previene la selección de componentes incompatibles e informa sobre las razones de incompatibilidad.
- Resumen financiero automático:
  - Costo Total de Compra del Ensamble.
  - Precio Sugerido de Venta Total.
  - Ganancia Neta Estimada.
  - Consumo Estimado de Energía en Watts.

### 4. Módulo de Ventas y Auditoría
- Registro de ventas individuales y agrupadas.
- Cálculo de distribución de ganancias por propietario en activos compartidos.
- Sistema de auditoría histórica de movimientos.
- Mantenimiento avanzado de sistema accesible de forma discreta a nivel de configuración.

---

## Tecnologías Utilizadas

- **Framework**: Flutter
- **Lenguaje**: Dart
- **Base de Datos en la Nube**: Google Cloud Firestore
- **Estilo de Diseño**: Cyber Cyan Dark Theme
