-- ============================================================
-- GRANJA DE HUEVOS — Esquema Supabase
-- Ejecutar en el SQL Editor de tu proyecto Supabase
-- ============================================================

-- 1. Lotes de gallinas (para calcular tasa de postura)
CREATE TABLE lotes_gallinas (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  nombre TEXT NOT NULL,
  cantidad_inicial INT NOT NULL,
  cantidad_actual INT NOT NULL,
  fecha_ingreso DATE NOT NULL DEFAULT CURRENT_DATE,
  raza TEXT,
  edad_semanas_ingreso INT,
  notas TEXT,
  activo BOOLEAN NOT NULL DEFAULT TRUE,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- 2. Producción diaria
CREATE TABLE produccion_diaria (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  fecha DATE NOT NULL,
  cantidad_huevos INT NOT NULL DEFAULT 0,
  huevos_rotos INT NOT NULL DEFAULT 0,
  huevos_descartados INT NOT NULL DEFAULT 0,
  lote_id UUID REFERENCES lotes_gallinas(id),
  notas TEXT,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  UNIQUE(fecha, lote_id)
);

-- 3. Clientes
CREATE TABLE clientes (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  nombre TEXT NOT NULL,
  telefono TEXT,
  direccion TEXT,
  notas TEXT,
  activo BOOLEAN NOT NULL DEFAULT TRUE,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- 4. Pedidos
CREATE TABLE pedidos (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  cliente_id UUID REFERENCES clientes(id),
  cliente_nombre TEXT,
  fecha_pedido DATE NOT NULL DEFAULT CURRENT_DATE,
  fecha_entrega DATE,
  cantidad_unidades INT NOT NULL,
  precio_unitario NUMERIC(10,2) NOT NULL DEFAULT 0.80,
  total NUMERIC(10,2) GENERATED ALWAYS AS (cantidad_unidades * precio_unitario) STORED,
  estado TEXT NOT NULL DEFAULT 'pendiente' CHECK (estado IN ('pendiente','entregado','cancelado')),
  notas TEXT,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- 5. Compras de insumos
CREATE TABLE compras (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  fecha DATE NOT NULL DEFAULT CURRENT_DATE,
  concepto TEXT NOT NULL,
  proveedor TEXT,
  cantidad NUMERIC(10,2),
  unidad TEXT,
  precio_unitario NUMERIC(10,2),
  total NUMERIC(10,2) NOT NULL,
  categoria TEXT NOT NULL DEFAULT 'alimento'
    CHECK (categoria IN ('alimento','medicinas','equipamiento','limpieza','transporte','otro')),
  notas TEXT,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- 6. Gastos generales
CREATE TABLE gastos (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  fecha DATE NOT NULL DEFAULT CURRENT_DATE,
  concepto TEXT NOT NULL,
  monto NUMERIC(10,2) NOT NULL,
  categoria TEXT NOT NULL DEFAULT 'operativo'
    CHECK (categoria IN ('luz','agua','transporte','mano_de_obra','veterinario','mantenimiento','operativo','otro')),
  notas TEXT,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- 7. Vista de stock actual
CREATE OR REPLACE VIEW stock_actual AS
SELECT
  COALESCE(SUM(p.cantidad_huevos), 0)
    - COALESCE(SUM(p.huevos_rotos), 0)
    - COALESCE(SUM(p.huevos_descartados), 0) AS total_producido_neto,
  COALESCE((
    SELECT SUM(pe.cantidad_unidades)
    FROM pedidos pe
    WHERE pe.estado = 'entregado'
  ), 0) AS total_vendido,
  COALESCE(SUM(p.cantidad_huevos), 0)
    - COALESCE(SUM(p.huevos_rotos), 0)
    - COALESCE(SUM(p.huevos_descartados), 0)
    - COALESCE((
        SELECT SUM(pe.cantidad_unidades)
        FROM pedidos pe
        WHERE pe.estado = 'entregado'
      ), 0) AS stock_disponible,
  COALESCE((
    SELECT SUM(pe.cantidad_unidades)
    FROM pedidos pe
    WHERE pe.estado = 'pendiente'
  ), 0) AS comprometido_pendiente
FROM produccion_diaria p;

-- 8. Vista resumen mensual
CREATE OR REPLACE VIEW resumen_mensual AS
SELECT
  DATE_TRUNC('month', fecha)::DATE AS mes,
  SUM(cantidad_huevos) AS huevos_producidos,
  SUM(huevos_rotos) AS huevos_rotos,
  SUM(huevos_descartados) AS huevos_descartados
FROM produccion_diaria
GROUP BY DATE_TRUNC('month', fecha)
ORDER BY mes DESC;

-- 9. Índices
CREATE INDEX idx_produccion_fecha ON produccion_diaria(fecha DESC);
CREATE INDEX idx_pedidos_estado ON pedidos(estado);
CREATE INDEX idx_pedidos_fecha ON pedidos(fecha_pedido DESC);
CREATE INDEX idx_compras_fecha ON compras(fecha DESC);
CREATE INDEX idx_gastos_fecha ON gastos(fecha DESC);

-- 10. RLS — desactivado para uso personal (activar si se agrega auth)
ALTER TABLE lotes_gallinas ENABLE ROW LEVEL SECURITY;
ALTER TABLE produccion_diaria ENABLE ROW LEVEL SECURITY;
ALTER TABLE clientes ENABLE ROW LEVEL SECURITY;
ALTER TABLE pedidos ENABLE ROW LEVEL SECURITY;
ALTER TABLE compras ENABLE ROW LEVEL SECURITY;
ALTER TABLE gastos ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Acceso total lotes" ON lotes_gallinas FOR ALL USING (true) WITH CHECK (true);
CREATE POLICY "Acceso total produccion" ON produccion_diaria FOR ALL USING (true) WITH CHECK (true);
CREATE POLICY "Acceso total clientes" ON clientes FOR ALL USING (true) WITH CHECK (true);
CREATE POLICY "Acceso total pedidos" ON pedidos FOR ALL USING (true) WITH CHECK (true);
CREATE POLICY "Acceso total compras" ON compras FOR ALL USING (true) WITH CHECK (true);
CREATE POLICY "Acceso total gastos" ON gastos FOR ALL USING (true) WITH CHECK (true);
