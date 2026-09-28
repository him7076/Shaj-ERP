import sys
path = r'c:\Users\lenovo\Desktop\Shaj ERP\lib\core\services\sync_service.dart'
with open(path, 'r', encoding='utf-8') as f:
    content = f.read()

content = content.replace(
    '_linkRemoteRelations(entityType, entity, data);',
    'await _linkRemoteRelations(entityType, entity, data);'
)

content = content.replace(
'''        case 'InvoiceItem':
          entity = InvoiceItem()
            ..itemName = data['itemName']''',
'''        case 'InvoiceItem':
          entity = InvoiceItem()
            ..itemId = data['itemId'] as int?
            ..itemName = data['itemName']'''
)

with open(path, 'w', encoding='utf-8') as f:
    f.write(content)
print('Patched successfully')
