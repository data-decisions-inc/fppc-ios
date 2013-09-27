/* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
 *
 * This file is part of xlslib -- A multiplatform, C/C++ library
 * for dynamic generation of Excel(TM) files.
 *
 * Copyright 2004 Yeico S. A. de C. V. All Rights Reserved.
 * Copyright 2008-2013 David Hoerl All Rights Reserved.
 *
 * Redistribution and use in source and binary forms, with or without modification, are
 * permitted provided that the following conditions are met:
 *
 *    1. Redistributions of source code must retain the above copyright notice, this list of
 *       conditions and the following disclaimer.
 *
 *    2. Redistributions in binary form must reproduce the above copyright notice, this list
 *       of conditions and the following disclaimer in the documentation and/or other materials
 *       provided with the distribution.
 *
 * THIS SOFTWARE IS PROVIDED BY David Hoerl ''AS IS'' AND ANY EXPRESS OR IMPLIED
 * WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND
 * FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL David Hoerl OR
 * CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR
 * CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR
 * SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON
 * ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING
 * NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF
 * ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 *
 * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * */

#include "../xlslib/record.h"
#include "../xlslib/datast.h"	// XTRACE2()      [i_a]
#include "../xlslib/rectypes.h"

// for factory:
#include "../xlslib/font.h"
#include "../xlslib/format.h"
#include "../xlslib/number.h"
#include "../xlslib/boolean.h"
#include "../xlslib/err.h"
#include "../xlslib/note.h"
#include "../xlslib/formula_cell.h"
#include "../xlslib/merged.h"
#include "../xlslib/label.h"
#include "../xlslib/index.h"
#include "../xlslib/extformat.h"
#include "../xlslib/continue.h"
#include "../xlslib/colinfo.h"
#include "../xlslib/blank.h"
#include "../xlslib/recdef.h"
#include "../xlslib/HPSF.h"

#ifdef __BCPLUSPLUS__
#include <malloc.h>
// malloc.h needed for calloc. RLN 111208
// They may be needed for other compilers as well
#include <memory.h>
// memory.h needed for memset. RLN 111215
// These may be needed for other compilers as well.
#endif

using namespace xlslib_strings;

namespace xlslib_core
{
	/*
	 ***********************************
	 *  CDataStorage class Implementation
	 ***********************************
	 */

	CDataStorage::CDataStorage() :
		store(),
		m_DataSize(0),
		m_FlushStack(),
		m_FlushLastEndLevel(0)
	{
		store.reserve(300);
		m_FlushLastEndPos = 0; // .begin();
	}

	CDataStorage::CDataStorage(size_t blobs) :
		store(),
		m_DataSize(0),
		m_FlushStack(),
		m_FlushLastEndLevel(0)
	{
		store.reserve(blobs);
		m_FlushLastEndPos = 0; // m_FlushStack.begin();
	}

	CDataStorage::~CDataStorage()
	{
		// Delete all the data. (Only if it exists)
		// flush all lingering units BEFORE we discard the associated UnitStore entities or we'll get a nasty assertion failure.
		FlushEm(BACKPATCH_LEVEL_EVERYONE);

		if (!store.empty()) {
			StoreList_Itor_t x0, x1;
			size_t cnt = 0;

			x0 = store.begin();
			x1 = store.end();
			for(StoreList_Itor_t di = x0; di != x1; ++di) {
				di->Reset();
				cnt++;
			}
			XTRACE2("ACTUAL: total storage unit count: ", cnt);
#if OLE_DEBUG
			std::cerr << "ACTUAL: total unit count: " << cnt << std::endl;
#endif
			store.resize(0);
		}
	}

	void CDataStorage::operator+=(CUnit* from)
	{
		/*
		 *  constructor already positioned the CUnit; make sure our assumption sticks:
		 *
		 *  we assume a usage style like this, i.e. += add in order AND BEFORE the next
		 *  unit is requested/constructed:
		 *
		 *   p1 = new CUnit(store, ...);
		 *   ...
		 *   store += p1;
		 *   p2 = new CUnit(store, ...);
		 *   ...
		 *   store += p2;
		 *
		 *  and we currently FAIL for any other 'mixed' usage pattern, e.g. this will b0rk:
		 *
		 *   p1 = new CUnit(store, ...);
		 *   p2 = new CUnit(store, ...);
		 *   ...
		 *   store += p1;
		 *   store += p2;
		 */
		XL_ASSERT(from->m_Index == (int)store.size() - 1);

		m_DataSize += from->GetDataSize();

		// and 'persist' the data associated with the CUnit from here-on after...
		// (that way, we can safely 'delete CUnit' and still have the data generated by the CUnit intact)
		store[(size_t)from->m_Index].MakeSticky();
		// and signal that we've made our data 'sticky':
		XL_ASSERT(from->m_Index >= 0);
		from->m_Index = -1 ^ from->m_Index;
		XL_ASSERT(from->m_Index < 0);
	}

	size_t CDataStorage::GetDataSize() const
	{
		return m_DataSize;
	}

	StoreList_Itor_t CDataStorage::begin()
	{
		return store.begin();
	}

	StoreList_Itor_t CDataStorage::end()
	{
		return store.end();
	}

	signed32_t CDataStorage::RequestIndex(size_t minimum_size)
	{
		signed32_t idx = static_cast<signed32_t>(store.size());
		CUnitStore &unit = *store.insert(store.end(), CUnitStore());

		if (unit.Prepare(minimum_size) != NO_ERRORS) {
			return INVALID_STORE_INDEX;
		}

		return idx;
	}

	CUnitStore& CDataStorage::operator[](signed32_t index)
	{
		XL_ASSERT(index != INVALID_STORE_INDEX);
		XL_ASSERT(index >= 0 ? index < (int)store.size() : 1);
		XL_ASSERT(index < 0 ? (~index) < (int)store.size() : 1);

		return index >= 0 ? store[(size_t)index] : store[~(size_t)index];
	}

	// Queue a new unit
	void CDataStorage::Push(CUnit* unit)
	{
		m_FlushStack.push_back(unit);
	}

	/*
	 * Clip to Max Data Size, as the rest of the record will be placed in continue records.
	 * This means that we will duplicate data. Its possible to create a new UnitStorage that takes just a pointer;
	 *     however, these records are quite rare, so why go to the effort.
	 */
	size_t CDataStorage::Clip(CUnit* unit)
	{
		XL_ASSERT(unit == m_FlushStack.back());
		CRecord *record = (CRecord *)unit;

		// Use this record, but only record the first big chunk
		record->SetRecordLength(MAX_RECORD_SIZE);

		// No way to directly change the size of a Unit's storage space, so we fake it by telling the UnitStore that its now smaller
		CUnitStore& unitStore = (*this)[record->GetIndex()];
		size_t realSize = unitStore.GetDataSize() - RECORD_HEADER_SIZE;
		unitStore.SetDataSize( MAX_RECORD_SIZE + RECORD_HEADER_SIZE );

		return realSize;
	}

	void CDataStorage::FlushEm(unsigned16_t backpatch_level)
	{
		/*
		 *  delete units which don't need to live any longer.
		 *
		 *  In the same loop, we shrink the 'stack' for
		 *  future speed and to keep storage requirements in check.
		 */
		//printf("FLUSH-EM %d\n", backpatch_level);
		UnitList_Itor_t start = m_FlushStack.begin();
		if (m_FlushLastEndLevel == backpatch_level
			&& backpatch_level != BACKPATCH_LEVEL_EVERYONE // do not use cached position when 'flushing all'
		    //&& m_FlushLastEndPos != m_FlushStack.begin()
			&& m_FlushLastEndPos != m_FlushStack.size()) { //.end())
			XL_ASSERT(start != m_FlushStack.end());
			start = m_FlushStack.begin() + (signed32_t)m_FlushLastEndPos;
			XL_ASSERT(m_FlushLastEndPos <= m_FlushStack.size());
			XL_ASSERT(start != m_FlushStack.end());
			start++;
		}

		UnitList_Itor_t j = start;
		size_t cnt = 0;
		size_t cntleft = 0;
		for (UnitList_Itor_t i = j; i != m_FlushStack.end(); i++) {
			CUnit *up = *i;
			if (up->m_Backpatching_Level <= backpatch_level) {
				XL_ASSERT(up != NULL);
				delete up;
				(*i) = NULL;
				cnt++;
				continue;
			}

			XL_ASSERT(up->m_Backpatching_Level <= 4);

			// do we need to move-copy the unit reference down as part of a shrink operation?
			if (i != j)	{
				(*j) = up;
			}
			j++;
			cntleft++;
		}

		size_t count = (size_t)(j - m_FlushStack.begin());

#if OLE_DEBUG
		std::cerr << "number of records deleted: " << cnt << ", left: " << cntleft << ", new.size: " << count << std::endl;
#endif

		m_FlushStack.resize(count);
		XL_ASSERT(m_FlushStack.size() == count);

		// remember for the next time around
		m_FlushLastEndLevel = backpatch_level;
		j = m_FlushStack.end();
		if (m_FlushStack.size() > 0) {
			j--;
		} else {
#if OLE_DEBUG
			std::cerr << "empty!" << std::endl;
#endif
		}
		m_FlushLastEndPos = (size_t)(j - m_FlushStack.begin());
	}

	void CDataStorage::FlushLowerLevelUnits(const CUnit *unit)
	{
		if (unit && unit->m_Backpatching_Level > 0) {
			FlushEm(unit->m_Backpatching_Level - 1);
		}
	}

	CUnit* CDataStorage::MakeCUnit()
	{
		return new CUnit(*this);
	}

	CRecord* CDataStorage::MakeCRecord()
	{
		return new CRecord(*this);
	}

	CRow* CDataStorage::MakeCRow(unsigned32_t rownum,
								 unsigned32_t firstcol,
								 unsigned32_t lastcol,
								 unsigned16_t rowheight,
								 const xf_t* xformat)
	{
		return new CRow(*this, rownum, firstcol, lastcol, rowheight, xformat);
	}

	CBof* CDataStorage::MakeCBof(unsigned16_t boftype)
	{
		return new CBof(*this, boftype);
	}

	CEof* CDataStorage::MakeCEof()
	{
		return new CEof(*this);
	}

	CDimension* CDataStorage::MakeCDimension(unsigned32_t minRow,
											 unsigned32_t maxRow,
											 unsigned32_t minCol,
											 unsigned32_t maxCol)
	{
		return new CDimension(*this, minRow, maxRow, minCol, maxCol);
	}

	CWindow1* CDataStorage::MakeCWindow1(const window1& wind1)
	{
		return new CWindow1(*this, wind1);
	}

	CWindow2* CDataStorage::MakeCWindow2(bool isActive)
	{
		return new CWindow2(*this, isActive);
	}

	CDateMode* CDataStorage::MakeCDateMode()
	{
		return new CDateMode(*this);
	}

	CStyle* CDataStorage::MakeCStyle(const style_t* styledef)
	{
		return new CStyle(*this, styledef);
	}

	CBSheet* CDataStorage::MakeCBSheet(const boundsheet_t* bsheetdef)
	{
		return new CBSheet(*this, bsheetdef);
	}

	CFormat* CDataStorage::MakeCFormat(const format_t* formatdef)
	{
		return new CFormat(*this, formatdef);
	}

	CFont* CDataStorage::MakeCFont(const font_t* fontdef)
	{
		return new CFont(*this, fontdef);
	}

	CNumber* CDataStorage::MakeCNumber(const number_t& numdef)
	{
		return new CNumber(*this, numdef);
	}

	CBoolean* CDataStorage::MakeCBoolean(const boolean_t& booldef)
	{
		return new CBoolean(*this, booldef);
	}

	CErr* CDataStorage::MakeCErr(const err_t& errdef)
	{
		return new CErr(*this, errdef);
	}

	CNote* CDataStorage::MakeCNote(const note_t& notedef)
	{
		return new CNote(*this, notedef);
	}

	CFormula* CDataStorage::MakeCFormula(const formula_cell_t& fdef)
	{
		return new CFormula(*this, fdef);
	}

	CMergedCells* CDataStorage::MakeCMergedCells()
	{
		return new CMergedCells(*this);
	}

	CLabel* CDataStorage::MakeCLabel(const label_t& labeldef)
	{
		return new CLabel(*this, labeldef);
	}

	CIndex* CDataStorage::MakeCIndex(unsigned32_t firstrow, unsigned32_t lastrow)
	{
		return new CIndex(*this, firstrow, lastrow);
	}

	CExtFormat* CDataStorage::MakeCExtFormat(const xf_t* xfdef)
	{
		return new CExtFormat(*this, xfdef);
	}

	CContinue* CDataStorage::MakeCContinue(CUnit* unit, const unsigned8_t* data, size_t size)
	{
		return new CContinue(unit, data, size);
	}

	CPalette* CDataStorage::MakeCPalette(const color_entry_t *colors)
	{
		return new CPalette(*this, colors);
	}

	CColInfo* CDataStorage::MakeCColInfo(const colinfo_t* newci)
	{
		return new CColInfo(*this, newci);
	}

	CBlank* CDataStorage::MakeCBlank(const blank_t& blankdef)
	{
		return new CBlank(*this, blankdef);
	}

	CCodePage* CDataStorage::MakeCCodePage(unsigned16_t boftype)
	{
		return new CCodePage(*this, boftype);
	}

	CDBCell* CDataStorage::MakeCDBCell(size_t startblock)
	{
		return new CDBCell(*this, startblock);
	}

	CHPSFdoc* CDataStorage::MakeCHPSFdoc(const hpsf_doc_t &docdef)
	{
		return new CHPSFdoc(*this, docdef);
	}

    CUnit* CDataStorage::MakeCExternBook(unsigned16_t sheet_count) {
        CRecord *supbook= new CRecord(*this);
        supbook->Inflate(8);
        supbook->SetRecordType(RECTYPE_SUPBOOK);
        supbook->SetRecordLength(4);
        supbook->AddValue16(sheet_count);
        supbook->AddValue8(0x01);
        supbook->AddValue8(0x04);

        return supbook;
    }

    CUnit* CDataStorage::MakeCExternSheet(const Boundsheet_Vect_t& sheets) {
        CRecord *externsheet= new CRecord(*this);
        externsheet->Inflate(4+2+sheets.size()*6);
        externsheet->SetRecordType(RECTYPE_EXTERNSHEET);
        externsheet->SetRecordLength(2+sheets.size()*6);
        externsheet->AddValue16(static_cast<unsigned16_t>(sheets.size()));
        for (size_t i=0; i<sheets.size(); i++) {
            externsheet->AddValue16(0);
            externsheet->AddValue16(static_cast<unsigned16_t>(i));
            externsheet->AddValue16(static_cast<unsigned16_t>(i));
        }
        return externsheet;
    }
#if 0
	CUnit* CDataStorage::MakeSST(const Label_Vect_t& labels)
	{
		CRecord *record = new CRecord(*this);
		size_t count = labels.size();
		record->SetAlreadyContinued(true);

		size_t offset = 0; // offset of last written data

		record->SetRecordTypeIndexed(RECTYPE_SST, 0);
		record->AddValue32(static_cast<unsigned32_t>(count)); // usages
		record->AddValue32(static_cast<unsigned32_t>(count)); // number of strings to follow

		size_t currSize = record->GetDataSize();

		cLabel_Vect_Itor_t label_end = labels.end();
		for(cLabel_Vect_Itor_t label = labels.begin(); label != label_end; ++label) {
			const label_t *currLabel = *label;
			u16string str16 = currLabel->GetStrLabel();

			size_t strLen;
			bool isAscii;
			size_t strSize = record->UnicodeStringLength(str16, strLen, isAscii, CUnit::LEN2_FLAGS_UNICODE /* = LEN2_FLAGS_UNICODE */ );
			if(strSize > MAX_RECORD_SIZE) {
				static const unsigned16_t tooLong[] = { 'L', 'e', 'n', 'g', 't', 'h', ' ', 't', 'o', 'o', ' ', 'l', 'o', 'n', 'g', '!' , 0};
				str16 = (xchar16_t *)(tooLong);	// cannot static_cast or const_cast this expression
				strSize = record->UnicodeStringLength(str16, strLen, isAscii, CUnit::LEN2_FLAGS_UNICODE /* = LEN2_FLAGS_UNICODE */ );
			}

			//printf("TEST: (currSize=%ld + strSize=%ld ) offset=%ld\n", currSize, strSize, offset);

			// Payload is always 4 less than currSize, so account for that here
			if((currSize + strSize) > (MAX_RECORD_SIZE+4)) {
				record->SetRecordLengthIndexed(currSize-RECORD_HEADER_SIZE, offset);

				offset = record->GetDataSize();         // new offset is where we are now
				//printf("CHUNK: size=%ld END=%ld\n", currSize, offset);
				record->AddFixedDataArray(0, 4);        // space for header
				record->SetRecordTypeIndexed(RECTYPE_CONTINUE, offset);
			}
			record->AddUnicodeString(str16, CUnit::LEN2_FLAGS_UNICODE);
			currSize = record->GetDataSize() - offset; // at end so its valid when we break out of the loop
			//printf("WROTE %ld bytes:  total=%ld currBlock=%ld offset=%ld\n", strSize, record->GetDataSize(), currSize, offset);
		}
		//totalSize = record->GetDataSize();		// total size of this record
		//printf("FINAL: cursize=%ld offset=%ld\n", currSize, offset);
		record->SetRecordLengthIndexed(currSize-RECORD_HEADER_SIZE, offset);

		//printf("TOTAL STRING SIZE: %ld\n", record->GetDataSize());
		return record;
	}
#endif
	CUnit* CDataStorage::MakeSST(const Label_Vect_t& labels)
	{
		CRecord *record = new CRecord(*this);
		size_t count = labels.size();
		record->SetAlreadyContinued(true);

		size_t offset = 0; // offset of last written data

		record->SetRecordTypeIndexed(RECTYPE_SST, 0);
		record->AddValue32(static_cast<unsigned32_t>(count)); // usages
		record->AddValue32(static_cast<unsigned32_t>(count)); // number of strings to follow

		size_t currSize = record->GetDataSize();

		cLabel_Vect_Itor_t label_end = labels.end();
		for(cLabel_Vect_Itor_t label = labels.begin(); label != label_end; ++label) {
			const label_t *currLabel = *label;
			u16string str16 = currLabel->GetStrLabel();

			size_t strLen;
			bool isAscii;
			size_t strSize = record->UnicodeStringLength(str16, strLen, isAscii, CUnit::LEN2_FLAGS_UNICODE /* = LEN2_FLAGS_UNICODE */ );
			if(strSize > MAX_RECORD_SIZE) {
				static const unsigned16_t tooLong[] = { 'L', 'e', 'n', 'g', 't', 'h', ' ', 't', 'o', 'o', ' ', 'l', 'o', 'n', 'g', '!' , 0};
				str16 = (xchar16_t *)(tooLong);	// cannot static_cast or const_cast this expression
				strSize = record->UnicodeStringLength(str16, strLen, isAscii, CUnit::LEN2_FLAGS_UNICODE /* = LEN2_FLAGS_UNICODE */ );
			}

			//printf("TEST: (currSize=%ld + strSize=%ld ) offset=%ld\n", currSize, strSize, offset);

			// Payload is always 4 less than currSize, so account for that here
			if((currSize + strSize) > (MAX_RECORD_SIZE+4)) {
				record->SetRecordLengthIndexed(currSize-RECORD_HEADER_SIZE, offset);

				offset = record->GetDataSize();         // new offset is where we are now
				//printf("CHUNK: size=%ld END=%ld\n", currSize, offset);
				record->AddFixedDataArray(0, 4);        // space for header
				record->SetRecordTypeIndexed(RECTYPE_CONTINUE, offset);
			}
			record->AddUnicodeString(str16, CUnit::LEN2_FLAGS_UNICODE);
			currSize = record->GetDataSize() - offset; // at end so its valid when we break out of the loop
			//printf("WROTE %ld bytes:  total=%ld currBlock=%ld offset=%ld\n", strSize, record->GetDataSize(), currSize, offset);
		}
		//totalSize = record->GetDataSize();		// total size of this record
		//printf("FINAL: cursize=%ld offset=%ld\n", currSize, offset);
		record->SetRecordLengthIndexed(currSize-RECORD_HEADER_SIZE, offset);

		//printf("TOTAL STRING SIZE: %ld\n", record->GetDataSize());
		return record;
	}

	CUnitStore::CUnitStore() :
		m_varying_width(false),
		m_is_in_use(false),
		m_is_sticky(false),
		m_nDataSize(0)
	{
		memset(&s, 0, sizeof(s));
		XL_ASSERT(s.vary.m_pData == NULL);
	}

	CUnitStore::~CUnitStore()
	{
		Reset();
		XL_ASSERT(s.vary.m_pData == NULL);
	}

	/*
	 *  This copy constructor is required as otherwise you'd get nuked by CDataStore
	 *  when it has to redimension its vector store when more units than
	 *  anticipated are requested: internally, STL detroys each unit during this
	 *  vector resize operation, so we'll need to copy the data to new space, especially
	 *  when we're m_varying_width !!!
	 */
	CUnitStore::CUnitStore(const CUnitStore &src)
	{
		if (&src == this) {
			return;
		}

		m_varying_width = src.m_varying_width;
		m_is_in_use = src.m_is_in_use;
		m_is_sticky = src.m_is_sticky;
		m_nDataSize = src.m_nDataSize;
		if (!m_varying_width) {
			XL_ASSERT(m_nDataSize <= FIXEDWIDTH_STORAGEUNIT_SIZE);
			memcpy(&s, &src.s, sizeof(s));
		} else {
			XL_ASSERT(m_is_in_use);
			XL_ASSERT(src.s.vary.m_nSize > 0);
			s.vary.m_pData = (unsigned8_t *)malloc(src.s.vary.m_nSize);
			if (!s.vary.m_pData) {
				// ret = ERR_UNABLE_TOALLOCATE_MEMORY;
				m_nDataSize = s.vary.m_nSize = 0;
			} else {
				memcpy(s.vary.m_pData, src.s.vary.m_pData, m_nDataSize);
				s.vary.m_nSize = src.s.vary.m_nSize;
			}
		}
	}

	signed8_t CUnitStore::Prepare(size_t minimum_size)
	{
		signed8_t ret = NO_ERRORS;

		// allocate space in the 'variable sized store' if we cannot fit in a fixed-width unit:
		if (minimum_size <= FIXEDWIDTH_STORAGEUNIT_SIZE) {
			m_varying_width = false;
			m_is_in_use = true;
			m_is_sticky = false;
			m_nDataSize = 0;
			memset(&s, 0, sizeof(s));

			// range: 0 ... +oo
		} else {
			m_varying_width = true;
			m_is_in_use = true;
			m_is_sticky = false;
			m_nDataSize = 0;
			memset(&s, 0, sizeof(s));
			XL_ASSERT(s.vary.m_pData == NULL);
			if (minimum_size > 0) {
				s.vary.m_pData = (unsigned8_t *)malloc(minimum_size);
				if (!s.vary.m_pData) {
					ret = ERR_UNABLE_TOALLOCATE_MEMORY;
					minimum_size = 0;
				}
				s.vary.m_nSize = minimum_size;
			}
		}

		return ret;
	}

	void CUnitStore::Reset()
	{
		if (m_varying_width && s.vary.m_pData) {
			XL_ASSERT(m_is_in_use);
			free((void *)s.vary.m_pData);
		}
		m_varying_width = false;
		m_is_in_use = false;
		m_is_sticky = false;
		m_nDataSize = 0;
		memset(&s, 0, sizeof(s));
		XL_ASSERT(s.vary.m_pData == NULL);
	}

	signed8_t CUnitStore::Resize(size_t newlen)
	{
		signed8_t ret = NO_ERRORS;

		XL_ASSERT(m_is_in_use);
		XL_ASSERT(newlen > 0);
		XL_ASSERT(newlen >= m_nDataSize);

		if (!m_varying_width) {
			if (newlen > FIXEDWIDTH_STORAGEUNIT_SIZE) {
				// turn this node into a varying-width unit store:
				unsigned8_t *p = (unsigned8_t *)malloc(newlen);
				if (!p)	{
					ret = ERR_UNABLE_TOALLOCATE_MEMORY;
					newlen = 0;
				} else {
					memcpy(p, s.fixed.m_pData, m_nDataSize);
				}
				s.vary.m_pData = p;
				s.vary.m_nSize = newlen;
				m_varying_width = true;
			}
		} else {
			if (newlen != s.vary.m_nSize) {
				if (!s.vary.m_pData) {
					XL_ASSERT(m_nDataSize == 0);
					s.vary.m_pData = (unsigned8_t *)malloc(newlen);
				} else {
					s.vary.m_pData = (unsigned8_t *)realloc((void *)s.vary.m_pData, newlen);
				}
				if (!s.vary.m_pData) {
					ret = ERR_UNABLE_TOALLOCATE_MEMORY;
					newlen = 0;
				}
				s.vary.m_nSize = newlen;
			}
		}

		return ret;
	}

	signed8_t CUnitStore::Init(const unsigned8_t *data, size_t size, size_t datasize)
	{
		signed8_t ret;

		XL_ASSERT(m_is_in_use);
		XL_ASSERT(size > 0);
		XL_ASSERT(datasize <= size);
		ret = Resize(size);
		if (ret == NO_ERRORS) {
			memcpy(GetBuffer(), data, datasize);
			SetDataSize(datasize);
		}
		return ret;
	}

	signed8_t CUnitStore::InitWithValue(unsigned8_t value, size_t size)
	{
		signed8_t ret;

		XL_ASSERT(m_is_in_use);
		XL_ASSERT(size > 0);
		ret = Resize(size);
		if (ret == NO_ERRORS) {
			memset(GetBuffer(), value, size);
			SetDataSize(size);
		}
		return ret;
	}
}