-- ============================================================
-- MIGRACION: Asegurar RLS con Supabase Auth
-- EJECUTAR SOLO DESPUES de crear tu usuario en Authentication
-- ============================================================

-- 1. Eliminar TODAS las politicas abiertas (6 originales + 2 de vendedores)
DROP POLICY IF EXISTS "Acceso total lotes" ON lotes_gallinas;
DROP POLICY IF EXISTS "Acceso total produccion" ON produccion_diaria;
DROP POLICY IF EXISTS "Acceso total clientes" ON clientes;
DROP POLICY IF EXISTS "Acceso total pedidos" ON pedidos;
DROP POLICY IF EXISTS "Acceso total compras" ON compras;
DROP POLICY IF EXISTS "Acceso total gastos" ON gastos;
DROP POLICY IF EXISTS "vendedores_all" ON vendedores;
DROP POLICY IF EXISTS "entregas_vendedor_all" ON entregas_vendedor;
DROP POLICY IF EXISTS "Acceso total vendedores" ON vendedores;
DROP POLICY IF EXISTS "Acceso total entregas_vendedor" ON entregas_vendedor;

-- 2. Habilitar RLS en las tablas de vendedores (por si no estaba)
ALTER TABLE IF EXISTS vendedores ENABLE ROW LEVEL SECURITY;
ALTER TABLE IF EXISTS entregas_vendedor ENABLE ROW LEVEL SECURITY;

-- 3. Crear politicas seguras: solo usuarios autenticados
CREATE POLICY "Solo usuarios autenticados" ON lotes_gallinas
  FOR ALL USING (auth.uid() IS NOT NULL) WITH CHECK (auth.uid() IS NOT NULL);

CREATE POLICY "Solo usuarios autenticados" ON produccion_diaria
  FOR ALL USING (auth.uid() IS NOT NULL) WITH CHECK (auth.uid() IS NOT NULL);

CREATE POLICY "Solo usuarios autenticados" ON clientes
  FOR ALL USING (auth.uid() IS NOT NULL) WITH CHECK (auth.uid() IS NOT NULL);

CREATE POLICY "Solo usuarios autenticados" ON pedidos
  FOR ALL USING (auth.uid() IS NOT NULL) WITH CHECK (auth.uid() IS NOT NULL);

CREATE POLICY "Solo usuarios autenticados" ON compras
  FOR ALL USING (auth.uid() IS NOT NULL) WITH CHECK (auth.uid() IS NOT NULL);

CREATE POLICY "Solo usuarios autenticados" ON gastos
  FOR ALL USING (auth.uid() IS NOT NULL) WITH CHECK (auth.uid() IS NOT NULL);

CREATE POLICY "Solo usuarios autenticados" ON vendedores
  FOR ALL USING (auth.uid() IS NOT NULL) WITH CHECK (auth.uid() IS NOT NULL);

CREATE POLICY "Solo usuarios autenticados" ON entregas_vendedor
  FOR ALL USING (auth.uid() IS NOT NULL) WITH CHECK (auth.uid() IS NOT NULL);

-- 4. Verificacion: debe mostrar 8 filas con policyname = 'Solo usuarios autenticados'
SELECT schemaname, tablename, policyname, permissive, qual
FROM pg_policies
WHERE policyname = 'Solo usuarios autenticados'
ORDER BY tablename;
