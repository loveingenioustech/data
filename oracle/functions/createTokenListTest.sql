DECLARE

  TYPE typTokenTab IS TABLE OF VARCHAR(20) INDEX BY BINARY_INTEGER;
  vglCityString VARCHAR2(200);

  tglTokenTab typTokenTab;

  --  ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
  --  Function: createTokenList
  --
  -- This function takes a string with "tokens" delimited by pDelimiter
  -- and put each "token" into a separate record in a PL/SQL collection. The
  -- PL/SQL collection is returned back to the caller of the function.
  --  ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
  FUNCTION createTokenList(pLine IN VARCHAR2, pDelimiter IN VARCHAR2)
    RETURN typTokenTab IS
    sLine     VARCHAR2(2000);
    nPos      INTEGER;
    nPosOld   INTEGER;
    nIndex    INTEGER;
    nLength   INTEGER;
    nCnt      INTEGER;
    sToken    VARCHAR2(200);
    tTokenTab typTokenTab;
  BEGIN
    sLine := pLine;
    IF (SUBSTR(sLine, LENGTH(sLine), 1) <> '|') THEN
      sLine := sLine || '|';
    END IF;
  
    nPos    := 0;
    sToken  := '';
    nLength := LENGTH(sLine);
    nCnt    := 0;
  
    FOR nIndex IN 1 .. nLength LOOP
      IF ((SUBSTR(sLine, nIndex, 1) = pDelimiter) OR (nIndex = nLength)) THEN
        nPosOld := nPos;
        nPos    := nIndex;
        nCnt    := nCnt + 1;
        sToken  := SUBSTR(sLine, nPosOld + 1, nPos - nPosOld - 1);
      
        tTokenTab(nCnt) := sToken;
      END IF;
    
    END LOOP;
  
    RETURN tTokenTab;
  END createTokenList;

BEGIN
  vglCityString := 'Paris#London#Rome#Oslo#Amsterdam#New York';

  tglTokenTab := createTokenList(vglCityString, '#');

  FOR indx IN tglTokenTab.FIRST .. tglTokenTab.LAST LOOP
    dbms_output.put_line('City:' || tglTokenTab(indx));
  END LOOP;

  tglTokenTab.DELETE;
END;
