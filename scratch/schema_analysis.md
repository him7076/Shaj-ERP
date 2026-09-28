# App Schema & Forms Analysis

This document lists all the forms (data models) in the application and their corresponding input fields.

## BankAccount Form
| Field Type | Field Name | Description / Notes |
|---|---|---|
| `String?` | **uuid** | |
| `String?` | **accountName** | |
| `String?` | **bankName** | |
| `String?` | **accountNumber** | |
| `String?` | **ifscCode** | |
| `String?` | **branchName** | |
| `double?` | **openingBalance** | |
| `double?` | **currentBalance** | |
| `bool` | **isPersonalVault** | |
| `bool` | **printOnInvoice** | |

## Brand Form
| Field Type | Field Name | Description / Notes |
|---|---|---|
| `String?` | **uuid** | |
| `String?` | **brandName** | |

## Category Form
| Field Type | Field Name | Description / Notes |
|---|---|---|
| `String?` | **uuid** | |
| `String?` | **categoryName** | |
| `String?` | **description** | |
| `String?` | **categoryType** | |
| `bool` | **isPersonalVault** | |

## CreditNote Form
| Field Type | Field Name | Description / Notes |
|---|---|---|
| `String?` | **uuid** | |
| `String?` | **creditNoteNumber** | |
| `DateTime?` | **creditNoteDate** | |
| `String?` | **originalInvoiceNumber** | |
| `String?` | **originalInvoiceUuid** | |
| `int?` | **partyId** | |
| `String?` | **partyName** | |
| `String?` | **gstNumber** | |
| `String?` | **address** | |
| `double?` | **subtotal** | |
| `double?` | **discountAmount** | |
| `double?` | **taxableAmount** | |
| `double?` | **cgstAmount** | |
| `double?` | **sgstAmount** | |
| `double?` | **igstAmount** | |
| `double?` | **totalGST** | |
| `double?` | **roundOff** | |
| `double?` | **grandTotal** | |
| `String?` | **remarks** | |
| `String?` | **createdBy** | |

## CreditNoteItem Form
| Field Type | Field Name | Description / Notes |
|---|---|---|
| `String?` | **uuid** | |
| `int?` | **itemId** | |
| `String?` | **itemName** | |
| `String?` | **hsnCode** | |
| `String?` | **selectedSubItemUuid** | |
| `String?` | **selectedSubItemName** | |
| `String?` | **description** | |
| `int?` | **parentCreditNoteId** | |
| `double?` | **quantity** | |
| `double?` | **freeQuantity** | |
| `String?` | **unit** | |
| `double?` | **rate** | |
| `double?` | **discount** | |
| `double?` | **taxableAmount** | |
| `double?` | **gstRate** | |
| `double?` | **gstAmount** | |
| `double?` | **totalAmount** | |
| `String?` | **batchNumber** | |
| `String?` | **expiryDate** | |
| `String?` | **mfgDate** | |

## DebitNote Form
| Field Type | Field Name | Description / Notes |
|---|---|---|
| `String?` | **uuid** | |
| `String?` | **debitNoteNumber** | |
| `DateTime?` | **debitNoteDate** | |
| `String?` | **originalPurchaseNumber** | |
| `String?` | **originalPurchaseUuid** | |
| `int?` | **partyId** | |
| `String?` | **partyName** | |
| `String?` | **gstNumber** | |
| `String?` | **address** | |
| `double?` | **subtotal** | |
| `double?` | **discountAmount** | |
| `double?` | **taxableAmount** | |
| `double?` | **cgstAmount** | |
| `double?` | **sgstAmount** | |
| `double?` | **igstAmount** | |
| `double?` | **totalGST** | |
| `double?` | **roundOff** | |
| `double?` | **grandTotal** | |
| `String?` | **remarks** | |
| `String?` | **createdBy** | |

## DebitNoteItem Form
| Field Type | Field Name | Description / Notes |
|---|---|---|
| `String?` | **uuid** | |
| `int?` | **itemId** | |
| `String?` | **itemName** | |
| `String?` | **hsnCode** | |
| `String?` | **selectedSubItemUuid** | |
| `String?` | **selectedSubItemName** | |
| `String?` | **description** | |
| `int?` | **parentDebitNoteId** | |
| `double?` | **quantity** | |
| `double?` | **freeQuantity** | |
| `String?` | **unit** | |
| `double?` | **rate** | |
| `double?` | **discount** | |
| `double?` | **taxableAmount** | |
| `double?` | **gstRate** | |
| `double?` | **gstAmount** | |
| `double?` | **totalAmount** | |
| `String?` | **batchNumber** | |
| `String?` | **expiryDate** | |
| `String?` | **mfgDate** | |

## DeletedVoucher Form
| Field Type | Field Name | Description / Notes |
|---|---|---|
| `String?` | **uuid** | |
| `String?` | **voucherType** | |
| `String?` | **voucherNumber** | |
| `String?` | **partyName** | |
| `double?` | **amount** | |
| `String?` | **remarks** | |
| `DateTime?` | **deletedAt** | |

## Expense Form
| Field Type | Field Name | Description / Notes |
|---|---|---|
| `String?` | **uuid** | |
| `String?` | **voucherNo** | |
| `String?` | **category** | |
| `String?` | **partyName** | |
| `double?` | **amount** | |
| `double?` | **subtotal** | |
| `double?` | **roundOff** | |
| `DateTime?` | **expenseDate** | |
| `String?` | **paymentMode** | |
| `String?` | **remarks** | |
| `String?` | **itemsJson** | |

## ExpenseItem Form
| Field Type | Field Name | Description / Notes |
|---|---|---|
| `String?` | **uuid** | |
| `String?` | **itemName** | |
| `double?` | **defaultRate** | |

## Invoice Form
| Field Type | Field Name | Description / Notes |
|---|---|---|
| `String?` | **uuid** | |
| `String?` | **invoiceNumber** | |
| `DateTime?` | **invoiceDate** | |
| `String?` | **invoiceType** | |
| `String?` | **invoiceStatus** | |
| `int?` | **sourceOrderId** | |
| `String?` | **sourceOrderNumber** | |
| `int?` | **partyId** | |
| `String?` | **partyName** | |
| `String?` | **gstNumber** | |
| `String?` | **address** | |
| `double?` | **subtotal** | |
| `double?` | **discountAmount** | |
| `double?` | **taxableAmount** | |
| `double?` | **cgstAmount** | |
| `double?` | **sgstAmount** | |
| `double?` | **igstAmount** | |
| `double?` | **totalGST** | |
| `double?` | **roundOff** | |
| `double?` | **grandTotal** | |
| `String?` | **paymentStatus** | |
| `double?` | **paidAmount** | |
| `double?` | **pendingAmount** | |
| `DateTime?` | **dueDate** | |
| `String?` | **remarks** | |
| `String?` | **termsAndConditions** | |
| `String?` | **cancelledBy** | |
| `DateTime?` | **cancelledDate** | |
| `String?` | **cancellationReason** | |
| `String?` | **createdBy** | |
| `String?` | **editedBy** | |
| `DateTime?` | **editTime** | |
| `bool?` | **isCashInvoice** | |
| `String?` | **linkedMachineUuid** | |
| `bool?` | **isServiceSameAsCurrent** | |

## InvoiceItem Form
| Field Type | Field Name | Description / Notes |
|---|---|---|
| `String?` | **uuid** | |
| `int?` | **itemId** | |
| `String?` | **itemName** | |
| `String?` | **hsnCode** | |
| `String?` | **selectedSubItemUuid** | |
| `String?` | **selectedSubItemName** | |
| `String?` | **description** | |
| `int?` | **parentInvoiceId** | |
| `String?` | **parentInvoiceUuid** | |
| `double?` | **quantity** | |
| `double?` | **freeQuantity** | |
| `String?` | **unit** | |
| `double?` | **rate** | |
| `double?` | **buyRate** | |
| `double?` | **discount** | |
| `double?` | **taxableAmount** | |
| `double?` | **gstRate** | |
| `double?` | **gstAmount** | |
| `double?` | **totalAmount** | |
| `String?` | **batchNumber** | |
| `String?` | **expiryDate** | |
| `String?` | **mfgDate** | |
| `bool` | **isBundle** | |
| `List<String>?` | **bundleComponentUuids** | |
| `List<double>?` | **bundleComponentQuantities** | |
| `List<String>?` | **bundleComponentUnits** | |
| `List<double>?` | **bundleComponentRates** | |
| `List<double>?` | **bundleComponentBuyRates** | |
| `List<double>?` | **bundleComponentGstPercents** | |
| `List<String>?` | **bundleComponentDescriptions** | |

## Item Form
| Field Type | Field Name | Description / Notes |
|---|---|---|
| `String?` | **uuid** | |
| `String?` | **itemCode** | |
| `String?` | **itemName** | |
| `String?` | **shortName** | |
| `String?` | **description** | |
| `String?` | **hsnCode** | |
| `bool` | **gstApplicable** | |
| `double?` | **gstRate** | |
| `double?` | **cessRate** | |
| `double?` | **buyRate** | |
| `double?` | **mrp** | |
| `double?` | **sellRate** | |
| `double?` | **wholesaleRate** | |
| `double?` | **minimumSellingPrice** | |
| `double?` | **openingStock** | |
| `double?` | **currentStock** | |
| `double?` | **reorderLevel** | |
| `double?` | **minimumStock** | |
| `String?` | **secondaryUnit** | |
| `String?` | **tertiaryUnit** | |
| `String?` | **primaryUnitName** | |
| `double?` | **conversionFactor** | |
| `double?` | **secondaryToTertiaryConversion** | |
| `String?` | **barcode** | |
| `String?` | **sku** | |
| `String?` | **skuCode** | |
| `List<String>?` | **imagePaths** | |
| `List<String>?` | **firebaseImageUrls** | |
| `String?` | **thumbnailImage** | |
| `double?` | **weight** | |
| `String?` | **dimensions** | |
| `String?` | **notes** | |
| `bool` | **enableBatchTracking** | |
| `String?` | **defaultBatchNumber** | |
| `bool` | **isBundle** | |
| `String?` | **itemType** | |
| `List<String>?` | **bundleComponentUuids** | |
| `List<double>?` | **bundleComponentQuantities** | |
| `List<String>?` | **bundleComponentUnits** | |
| `bool` | **hasSubItems** | |
| `List<SubItem>?` | **subItems** | |
| `String?` | **uuid** | |
| `String?` | **name** | |
| `String?` | **localPhotoPath** | |
| `String?` | **googlePhotoLink** | |
| `double?` | **buyPrice** | |
| `double?` | **sellPrice** | |

## MachineryCategory Form
| Field Type | Field Name | Description / Notes |
|---|---|---|
| `String?` | **uuid** | |
| `String?` | **categoryName** | |
| `String?` | **description** | |

## Machinery Form
| Field Type | Field Name | Description / Notes |
|---|---|---|
| `String?` | **uuid** | |
| `String?` | **partyUuid** | |
| `String?` | **categoryUuid** | |
| `String?` | **machineName** | |
| `String?` | **brandName** | |
| `String?` | **modelNumber** | |
| `String?` | **serialNumber** | |
| `String?` | **description** | |
| `List<String>?` | **photos** | |
| `String?` | **googlePhotosLink** | |
| `int?` | **serviceIntervalMonths** | |
| `int?` | **serviceIntervalDays** | |
| `DateTime?` | **lastServiceDate** | |
| `DateTime?` | **nextServiceDate** | |

## Order Form
| Field Type | Field Name | Description / Notes |
|---|---|---|
| `String?` | **uuid** | |
| `String?` | **orderNumber** | |
| `DateTime?` | **orderDate** | |
| `String?` | **status** | |
| `int?` | **partyId** | |
| `String?` | **partyName** | |
| `String?` | **mobileNumber** | |
| `String?` | **gstNumber** | |
| `double?` | **latitude** | |
| `double?` | **longitude** | |
| `String?` | **locationAddress** | |
| `String?` | **locationUrl** | |
| `double?` | **subtotal** | |
| `double?` | **discountAmount** | |
| `double?` | **discountPercent** | |
| `double?` | **totalGST** | |
| `double?` | **roundOff** | |
| `double?` | **grandTotal** | |
| `String?` | **remarks** | |
| `String?` | **internalNotes** | |
| `String?` | **cancelledBy** | |
| `DateTime?` | **cancelledDate** | |
| `String?` | **cancellationReason** | |
| `String?` | **createdBy** | |
| `String?` | **editedBy** | |
| `DateTime?` | **editTime** | |

## OrderItem Form
| Field Type | Field Name | Description / Notes |
|---|---|---|
| `String?` | **uuid** | |
| `int?` | **itemId** | |
| `String?` | **itemName** | |
| `String?` | **hsnCode** | |
| `String?` | **selectedSubItemUuid** | |
| `String?` | **selectedSubItemName** | |
| `String?` | **description** | |
| `int?` | **orderId** | |
| `String?` | **orderUuid** | |
| `double?` | **quantity** | |
| `double?` | **freeQuantity** | |
| `String?` | **unit** | |
| `double?` | **rate** | |
| `double?` | **discountPercent** | |
| `double?` | **discountAmount** | |
| `double?` | **taxableAmount** | |
| `double?` | **gstPercent** | |
| `double?` | **gstAmount** | |
| `double?` | **totalAmount** | |
| `String?` | **batchNumber** | |
| `String?` | **expiryDate** | |
| `String?` | **mfgDate** | |

## Party Form
| Field Type | Field Name | Description / Notes |
|---|---|---|
| `String?` | **uuid** | |
| `String?` | **partyCode** | |
| `String?` | **partyName** | |
| `String?` | **partyType** | |
| `String?` | **mobileNumber** | |
| `String?` | **whatsappNumber** | |
| `String?` | **email** | |
| `String?` | **gstNumber** | |
| `String?` | **panNumber** | |
| `String?` | **gstType** | |
| `String?` | **addressLine1** | |
| `String?` | **addressLine2** | |
| `String?` | **city** | |
| `String?` | **state** | |
| `String?` | **pincode** | |
| `double?` | **latitude** | |
| `double?` | **longitude** | |
| `String?` | **locationAddress** | |
| `String?` | **googleMapUrl** | |
| `double?` | **openingBalance** | |
| `String?` | **balanceType** | |
| `double?` | **creditLimit** | |
| `double?` | **outstandingBalance** | |
| `String?` | **paymentTerms** | |
| `int?` | **dueDays** | |
| `String?` | **contactPerson** | |
| `String?` | **businessCategory** | |
| `String?` | **notes** | |
| `List<String>?` | **shopPhotos** | |
| `List<String>?` | **shopPhotoUrls** | |
| `List<PartyMobile>?` | **mobileNumbers** | |
| `List<PartyAddress>?` | **addresses** | |
| `String?` | **referenceName** | |
| `String?` | **label** | |
| `String?` | **number** | |
| `String?` | **label** | |
| `String?` | **fullAddress** | |
| `double?` | **latitude** | |
| `double?` | **longitude** | |

## Purchase Form
| Field Type | Field Name | Description / Notes |
|---|---|---|
| `String?` | **uuid** | |
| `String?` | **purchaseNumber** | |
| `String?` | **supplierInvoiceNumber** | |
| `DateTime?` | **purchaseDate** | |
| `int?` | **partyId** | |
| `String?` | **partyName** | |
| `String?` | **gstNumber** | |
| `String?` | **address** | |
| `double?` | **subtotal** | |
| `double?` | **discountAmount** | |
| `double?` | **taxableAmount** | |
| `double?` | **cgstAmount** | |
| `double?` | **sgstAmount** | |
| `double?` | **igstAmount** | |
| `double?` | **totalGST** | |
| `double?` | **roundOff** | |
| `double?` | **grandTotal** | |
| `String?` | **paymentStatus** | |
| `double?` | **paidAmount** | |
| `double?` | **pendingAmount** | |
| `String?` | **remarks** | |

## PurchaseItem Form
| Field Type | Field Name | Description / Notes |
|---|---|---|
| `String?` | **uuid** | |
| `int?` | **purchaseId** | |
| `String?` | **purchaseUuid** | |
| `int?` | **itemId** | |
| `String?` | **itemName** | |
| `String?` | **hsnCode** | |
| `String?` | **selectedSubItemUuid** | |
| `String?` | **selectedSubItemName** | |
| `String?` | **description** | |
| `double?` | **quantity** | |
| `String?` | **unit** | |
| `double?` | **rate** | |
| `double?` | **discount** | |
| `double?` | **taxableAmount** | |
| `double?` | **gstRate** | |
| `double?` | **gstAmount** | |
| `double?` | **totalAmount** | |
| `String?` | **batchNumber** | |
| `String?` | **expiryDate** | |
| `String?` | **mfgDate** | |
| `bool` | **isBundle** | |
| `List<String>?` | **bundleComponentUuids** | |
| `List<double>?` | **bundleComponentQuantities** | |
| `List<String>?` | **bundleComponentUnits** | |
| `List<double>?` | **bundleComponentRates** | |
| `List<double>?` | **bundleComponentBuyRates** | |
| `List<double>?` | **bundleComponentGstPercents** | |
| `List<String>?` | **bundleComponentDescriptions** | |

## Settings Form
| Field Type | Field Name | Description / Notes |
|---|---|---|
| `String?` | **uuid** | |
| `String?` | **companyName** | |
| `String?` | **companyGST** | |
| `String?` | **companyAddress** | |
| `String?` | **companyPhone** | |
| `String?` | **companyEmail** | |
| `String?` | **logoPath** | |
| `String?` | **themeMode** | |

## StockAdjustment Form
| Field Type | Field Name | Description / Notes |
|---|---|---|
| `String?` | **uuid** | |
| `String?` | **itemUuid** | |
| `int?` | **itemId** | |
| `String?` | **itemName** | |
| `String?` | **adjustmentType** | |
| `double?` | **quantity** | |
| `String?` | **unit** | |
| `double?` | **ratePerUnit** | |
| `double?` | **totalValue** | |
| `DateTime?` | **adjustmentDate** | |
| `String?` | **reason** | |
| `String?` | **notes** | |

## SyncQueue Form
| Field Type | Field Name | Description / Notes |
|---|---|---|
| `String?` | **uuid** | |
| `String?` | **entityType** | |
| `int?` | **entityId** | |
| `String?` | **entityUuid** | |
| `String?` | **operation** | |
| `int` | **retryCount** | |
| `DateTime?` | **lastAttempt** | |
| `String?` | **lastError** | |

## Task Form
| Field Type | Field Name | Description / Notes |
|---|---|---|
| `String?` | **uuid** | |
| `String?` | **title** | |
| `String?` | **description** | |
| `String?` | **status** | |
| `String?` | **priority** | |
| `DateTime?` | **dueDate** | |
| `DateTime?` | **completedAt** | |
| `String?` | **subtasksJson** | |
| `int?` | **estimatedTimeMinutes** | |
| `List<String>?` | **linkedItemUuids** | |
| `bool` | **isPersonalVault** | |

## Transaction Form
| Field Type | Field Name | Description / Notes |
|---|---|---|
| `String?` | **uuid** | |
| `String?` | **transactionNumber** | |
| `DateTime?` | **transactionDate** | |
| `String?` | **partyUuid** | |
| `String?` | **partyName** | |
| `String?` | **transactionType** | |
| `double?` | **amount** | |
| `String?` | **paymentMode** | |
| `String?` | **paymentStatus** | |
| `String?` | **referenceNumber** | |
| `String?` | **remarks** | |
| `String?` | **linkedBillUuid** | |
| `String?` | **linkedBillNumber** | |
| `String?` | **targetPartyUuid** | |
| `String?` | **targetPartyName** | |
| `String?` | **categoryUuid** | |
| `String?` | **categoryName** | |
| `String?` | **subCategoryUuid** | |
| `String?` | **subCategoryName** | |
| `List<String>?` | **tags** | |
| `double?` | **transferFee** | |
| `bool` | **isPersonalVault** | |

## Unit Form
| Field Type | Field Name | Description / Notes |
|---|---|---|
| `String?` | **uuid** | |
| `String?` | **unitName** | |
| `String?` | **shortName** | |
| `bool` | **isSecondary** | |

## User Form
| Field Type | Field Name | Description / Notes |
|---|---|---|
| `String?` | **uuid** | |
| `String?` | **name** | |
| `String?` | **email** | |
| `String?` | **role** | |

## WhatsAppMapping Form
| Field Type | Field Name | Description / Notes |
|---|---|---|
| `String?` | **uuid** | |
| `String?` | **mappingType** | |
| `String?` | **rawKey** | |
| `String?` | **targetUuid** | |
| `double?` | **pcsPerBundle** | |
| `double?` | **pcsPerCarton** | |
| `double?` | **customRate** | |
| `String?` | **rateUnit** | |
| `bool?` | **isTaxInclusive** | |

