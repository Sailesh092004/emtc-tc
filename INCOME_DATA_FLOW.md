# Income Data Flow: DPR → MPR → Backend

## Overview
This document describes how income and occupation data flows from DPR (Demographic Particulars Return) to MPR (Monthly Purchase Return) and how it's handled in the backend submission.

## Data Flow Architecture

### 1. DPR Data Capture
**File**: `lib/screens/dpr_form.dart`
- **Income Fields per Household Member**:
  - `annualIncomeJob`: Annual income from job/business
  - `annualIncomeOther`: Annual income from other sources
  - `otherIncomeSource`: Name/description of other income source
  - `totalIncome`: Auto-calculated total (job + other)
- **Occupation Field per Member**:
  - `occupation`: Standardized occupation code (01-14)
- **Persistence**: All data is stored locally in SQLite and synced to backend

### 2. MPR Data Auto-Fill
**File**: `lib/screens/mpr_form.dart`
- **Trigger**: When user enters Centre Code + Return No. that matches existing DPR
- **Auto-Filled Fields**:
  - `occupationOfHead`: Occupation of head of family (from DPR)
  - `annualIncomeJob`: Job income of head of family
  - `annualIncomeOther`: Other income of head of family
  - `otherIncomeSource`: Other income source name
  - `totalIncome`: Total income of head of family
- **UI State**: Income fields appear as read-only when auto-filled from DPR

### 3. MPR Submission
**File**: `lib/services/api_service.dart`
- **Required Fields**: Standard MPR fields (name, address, items, etc.)
- **Optional Income Fields**: Included only when available from DPR
  - `annual_income_job`: Job income (if available)
  - `annual_income_other`: Other income (if available)
  - `other_income_source`: Income source name (if available)
  - `total_income`: Total income (if available)

## Backend Contract

### MPR Submission Payload
```json
{
  "name_and_address": "string",
  "district_state_tel": "string",
  "panel_centre": "string",
  "centre_code": "string",
  "return_no": "string",
  "family_size": "integer",
  "income_group": "string",
  "month_and_year": "string",
  "occupation_of_head": "string",
  "items": [...],
  "latitude": "float",
  "longitude": "float",
  "otp_code": "string",
  
  // Optional income fields (only included when available from DPR)
  "annual_income_job": "float",
  "annual_income_other": "float", 
  "other_income_source": "string",
  "total_income": "float"
}
```

### Backend Expectations
- **Required**: All standard MPR fields
- **Optional**: Income fields are included for reference/audit purposes
- **Data Source**: Income data comes from linked DPR record
- **Validation**: Backend should accept MPR submissions with or without income fields

## Implementation Details

### DPR Form (`lib/screens/dpr_form.dart`)
- ✅ Income fields properly captured per household member
- ✅ Occupation dropdown using standardized codes
- ✅ Data persistence to local SQLite database
- ✅ Backend sync functionality

### MPR Form (`lib/screens/mpr_form.dart`)
- ✅ Auto-fill from DPR when Centre Code + Return No. match
- ✅ Income fields displayed as read-only when auto-filled
- ✅ Occupation auto-filled from DPR head of family
- ✅ Form submission includes income data when available

### MPR Model (`lib/models/mpr.dart`)
- ✅ Income fields added as optional parameters
- ✅ Backward compatibility maintained
- ✅ Data serialization/deserialization support

### API Service (`lib/services/api_service.dart`)
- ✅ MPR submission includes income data when available
- ✅ Both sync and update operations support income fields
- ✅ Conditional inclusion based on data availability

## Usage Scenarios

### Scenario 1: New MPR with DPR Link
1. User enters Centre Code + Return No.
2. System auto-fills MPR with DPR data (including income)
3. Income fields appear as read-only reference
4. MPR submission includes income data for backend

### Scenario 2: New MPR without DPR Link
1. User manually fills MPR form
2. No income fields displayed
3. MPR submission includes only standard fields

### Scenario 3: Edit Existing MPR
1. System loads MPR data including income fields
2. Income fields displayed as read-only
3. Form submission preserves income data

## Benefits

1. **Data Consistency**: Income data flows seamlessly from DPR to MPR
2. **User Experience**: Auto-fill reduces manual data entry
3. **Data Integrity**: Standardized codes prevent invalid entries
4. **Audit Trail**: Income information available for reference in MPR
5. **Flexibility**: Backend can use income data as needed

## Future Considerations

1. **Backend Processing**: Backend may use income data for analytics
2. **Data Validation**: Additional validation rules for income fields
3. **Reporting**: Income data available for MPR reports
4. **Compliance**: Income data may be required for regulatory purposes

## Files Modified

- `lib/screens/dpr_form.dart` - Enhanced dropdown implementation
- `lib/screens/mpr_form.dart` - Added income fields and auto-fill
- `lib/models/mpr.dart` - Extended MPR model with income fields
- `lib/services/api_service.dart` - Updated API submission to include income data
- `INCOME_DATA_FLOW.md` - This documentation file

## Commit Message
```
feat(dpr): capture income and occupation; wire for availability in flows

- Enhanced DPR form with proper dropdowns for income and occupation
- Added income fields to MPR form for DPR data reference
- Implemented auto-fill from DPR to MPR with income data
- Updated MPR submission to include income fields when available
- Added comprehensive documentation for income data flow
``` 