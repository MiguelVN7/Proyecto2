// SCRIPT DE PRUEBA - Ejecuta esto en la consola del navegador (F12)
// Para diagnosticar el problema de cambiar estados

console.log('=== DIAGNÓSTICO DE CAMBIAR ESTADOS ===');

// 1. Verificar que existen los selectores
const selectores = document.querySelectorAll('.estado-selector');
console.log(`✓ Encontrados ${selectores.length} selectores de estado`);

// 2. Verificar que existen los botones
const botones = document.querySelectorAll('.btn-cambiar-estado');
console.log(`✓ Encontrados ${botones.length} botones "Aplicar"`);

// 3. Ver el primer selector
if (selectores.length > 0) {
    const primer = selectores[0];
    console.log('Primer selector:', {
        reporteId: primer.dataset.reporteId,
        estadoActual: primer.dataset.estadoActual,
        valorSeleccionado: primer.value
    });
}

// 4. Forzar mostrar todos los botones (para testing)
console.log('Mostrando todos los botones para testing...');
botones.forEach((btn, i) => {
    btn.style.display = 'inline-block';
    console.log(`  Botón ${i+1}: Reporte ${btn.dataset.reporteId}`);
});

// 5. Agregar listener temporal para ver eventos
selectores.forEach((selector, i) => {
    selector.addEventListener('change', function(e) {
        console.log(`📝 Selector ${i+1} cambió:`, {
            reporteId: selector.dataset.reporteId,
            desde: selector.dataset.estadoActual,
            hacia: selector.value
        });
    });
});

// 6. Agregar listener a botones
botones.forEach((btn, i) => {
    btn.addEventListener('click', function(e) {
        console.log(`🖱️ Click en botón ${i+1}:`, {
            reporteId: btn.dataset.reporteId
        });
    });
});

console.log('=== DIAGNÓSTICO COMPLETO ===');
console.log('Ahora intenta cambiar el estado de un reporte y observa los logs');
console.log('Si ves los logs, el problema está en el fetch()');
console.log('Si NO ves los logs, el problema está en los event listeners');
