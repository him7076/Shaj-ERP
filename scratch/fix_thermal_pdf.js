const fs = require('fs');

let c = fs.readFileSync('lib/core/services/pdf_service.dart', 'utf8');
let original = c;

// Fix Phone
c = c.replace(/pw\.Text\('Ph: ',\s*style:\s*const\s*pw\.TextStyle\(fontSize:\s*8\),\s*textAlign:\s*pw\.TextAlign\.center\),/g, `pw.Text('Ph: \${firmInfo.phone}', style: const pw.TextStyle(fontSize: 8), textAlign: pw.TextAlign.center),`);

// Fix GST
c = c.replace(/pw\.Text\('GSTIN: ',\s*style:\s*pw\.TextStyle\(fontSize:\s*8,\s*fontWeight:\s*pw\.FontWeight\.bold\),\s*textAlign:\s*pw\.TextAlign\.center\),/g, `pw.Text('GSTIN: \${firmInfo.gst}', style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold), textAlign: pw.TextAlign.center),`);

// Fix FSSAI
c = c.replace(/pw\.Text\('FSSAI: ',\s*style:\s*pw\.TextStyle\(fontSize:\s*8,\s*fontWeight:\s*pw\.FontWeight\.bold\),\s*textAlign:\s*pw\.TextAlign\.center\),/g, `pw.Text('FSSAI: \${firmInfo.fssai}', style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold), textAlign: pw.TextAlign.center),`);

// Fix Inv No and Date
c = c.replace(/pw\.Text\('Inv No: ',\s*style:\s*const\s*pw\.TextStyle\(fontSize:\s*8\)\),/g, `pw.Text('Inv No: \${invoice.invoiceNumber ?? ""}', style: const pw.TextStyle(fontSize: 8)),`);
c = c.replace(/pw\.Text\('Date: ',\s*style:\s*const\s*pw\.TextStyle\(fontSize:\s*8\)\),/g, `pw.Text('Date: \${invoice.invoiceDate != null ? DateFormat("dd MMM yyyy").format(invoice.invoiceDate!) : ""}', style: const pw.TextStyle(fontSize: 8)),`);

// Fix Customer
c = c.replace(/pw\.Text\('Customer: ',\s*style:\s*const\s*pw\.TextStyle\(fontSize:\s*8\)\)/g, `pw.Text('Customer: \${invoice.partyName ?? "Cash"}', style: const pw.TextStyle(fontSize: 8))`);

// Fix Table Headers (Give Rate and Amt more flex/space)
// The original uses: Expanded(flex: 1, child: pw.Text('Rate', ...))
c = c.replace(/pw\.Expanded\(flex: 1, child: pw\.Text\('Rate',\s*style:\s*pw\.TextStyle\(fontSize:\s*8,\s*fontWeight:\s*pw\.FontWeight\.bold\),\s*textAlign:\s*pw\.TextAlign\.right\)\),/g, `pw.Expanded(flex: 2, child: pw.Text('Rate', style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold), textAlign: pw.TextAlign.right)),`);
c = c.replace(/pw\.Expanded\(flex: 1, child: pw\.Text\('Amt',\s*style:\s*pw\.TextStyle\(fontSize:\s*8,\s*fontWeight:\s*pw\.FontWeight\.bold\),\s*textAlign:\s*pw\.TextAlign\.right\)\),/g, `pw.Expanded(flex: 2, child: pw.Text('Amt', style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold), textAlign: pw.TextAlign.right)),`);

// Fix Table Rows (Give Rate and Amt more flex/space)
c = c.replace(/pw\.Expanded\(flex: 1, child: pw\.Text\(rate\.toStringAsFixed\(2\),\s*style:\s*const\s*pw\.TextStyle\(fontSize:\s*8\),\s*textAlign:\s*pw\.TextAlign\.right\)\),/g, `pw.Expanded(flex: 2, child: pw.Text(rate.toStringAsFixed(2), style: const pw.TextStyle(fontSize: 8), textAlign: pw.TextAlign.right)),`);
c = c.replace(/pw\.Expanded\(flex: 1, child: pw\.Text\(amt\.toStringAsFixed\(2\),\s*style:\s*const\s*pw\.TextStyle\(fontSize:\s*8\),\s*textAlign:\s*pw\.TextAlign\.right\)\),/g, `pw.Expanded(flex: 2, child: pw.Text(amt.toStringAsFixed(2), style: const pw.TextStyle(fontSize: 8), textAlign: pw.TextAlign.right)),`);

fs.writeFileSync('lib/core/services/pdf_service.dart', c, 'utf8');
console.log('Fixed thermal pdf in pdf_service.dart');
