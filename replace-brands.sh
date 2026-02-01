#!/bin/bash

# Script para reemplazar marcas KOF, FEMSA y Coca-Cola por ORSTED CORP en múltiples repositorios
# Autor: José Luis Cruz
# Fecha: 2026-02-01

set -e  # Salir si hay algún error

# Configuración
GITHUB_USER="Joseluiscruz-hub"
BRANCH_NAME="rebrand-to-orsted-corp"
NEW_BRAND="ORSTED CORP"

# Lista de repositorios a procesar
REPOS=(
    "EscaneodeMaterialesKOF"
    "femsa-safety-check"
    "Femsa-Check-List"
    "Check-List-Estivado-y-verticalidad"
    "checklist-verticalidad"
    "checklist-de-seguridad-para-montacargas"
    "Inventory-Scanner-Pro-2"
    "FemsaApp"
    "femsa-digital-inspection-pwa"
    "Verticalidad"
    "Check-List-de-Verticalidad"
)

echo "=== Iniciando proceso de reemplazo de marcas ==="
echo "Usuario: $GITHUB_USER"
echo "Nueva marca: $NEW_BRAND"
echo "Total de repositorios: ${#REPOS[@]}"
echo ""

# Contador
processed=0
success=0
failed=0

# Procesar cada repositorio
for repo in "${REPOS[@]}"; do
    ((processed++))
    echo "[$processed/${#REPOS[@]}] Procesando: $repo"
    
    # Crear directorio temporal
    temp_dir="/tmp/brand-replacement-$repo"
    rm -rf "$temp_dir"
    
    # Clonar repositorio
    echo "  → Clonando repositorio..."
    if git clone "https://github.com/$GITHUB_USER/$repo.git" "$temp_dir" 2>/dev/null; then
        cd "$temp_dir"
        
        # Crear nueva rama
        echo "  → Creando rama $BRANCH_NAME..."
        git checkout -b "$BRANCH_NAME"
        
        # Encontrar y reemplazar en archivos
        echo "  → Buscando y reemplazando menciones..."
        
        # Buscar archivos relevantes (excluir binarios y carpetas git)
        files_changed=0
        while IFS= read -r -d '' file; do
            # Verificar si el archivo contiene alguna de las marcas
            if grep -q -E 'KOF|FEMSA|Coca-Cola|Coca Cola' "$file" 2>/dev/null; then
                # Hacer reemplazos
                sed -i "s/KOF/$NEW_BRAND/g" "$file"
                sed -i "s/FEMSA/$NEW_BRAND/g" "$file"
                sed -i "s/Coca-Cola/$NEW_BRAND/g" "$file"
                sed -i "s/Coca Cola/$NEW_BRAND/g" "$file"
                ((files_changed++))
            fi
        done < <(find . -type f -not -path '*/.git/*' -not -path '*/node_modules/*' -not -path '*/build/*' -not -path '*/dist/*' \( -name '*.md' -o -name '*.txt' -o -name '*.java' -o -name '*.kt' -o -name '*.xml' -o -name '*.json' -o -name '*.gradle' -o -name '*.ts' -o -name '*.js' -o -name '*.html' -o -name '*.css' \) -print0)
        
        if [ $files_changed -gt 0 ]; then
            echo "  → Archivos modificados: $files_changed"
            
            # Añadir cambios
            git add .
            
            # Commit
            git commit -m "Rebrand: Replace KOF, FEMSA, and Coca-Cola with $NEW_BRAND

Updated all brand references to reflect new ownership.
- KOF → $NEW_BRAND
- FEMSA → $NEW_BRAND  
- Coca-Cola → $NEW_BRAND

Affected files: $files_changed"
            
            # Push rama (requiere autenticación)
            echo "  → Pushing cambios..."
            if git push origin "$BRANCH_NAME" 2>/dev/null; then
                echo "  ✓ Pull request listo para crear en: https://github.com/$GITHUB_USER/$repo/compare/main...$BRANCH_NAME"
                ((success++))
            else
                echo "  ✗ Error al hacer push. Verifica permisos."
                ((failed++))
            fi
        else
            echo "  ℹ No se encontraron menciones de las marcas antiguas"
        fi
        
        # Limpiar
        cd /
        rm -rf "$temp_dir"
    else
        echo "  ✗ Error al clonar el repositorio"
        ((failed++))
    fi
    
    echo ""
done

echo "=== Resumen del proceso ==="
echo "Repositorios procesados: $processed"
echo "Exitosos: $success"
echo "Fallidos: $failed"
echo ""
echo "Para crear los PRs, visita los siguientes enlaces:"
for repo in "${REPOS[@]}"; do
    echo "  https://github.com/$GITHUB_USER/$repo/compare/main...$BRANCH_NAME"
done
