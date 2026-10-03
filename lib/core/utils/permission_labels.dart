/// 'sales_invoices.read' -> group 'sales_invoices', action 'read'
String permissionGroup(String key) =>
    key.contains('.') ? key.substring(0, key.indexOf('.')) : key;

String permissionAction(String key) =>
    key.contains('.') ? key.substring(key.indexOf('.') + 1) : key;

/// 'sales_invoices' -> 'Sales Invoices'
String titleCase(String snake) => snake
    .split('_')
    .map((w) => w.isEmpty ? w : '${w[0].toUpperCase()}${w.substring(1)}')
    .join(' ');
