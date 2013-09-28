DECLARE
  vglNotesString VARCHAR2(2000);

  FUNCTION getToken(pString    IN VARCHAR2,
                    pPosition  IN INTEGER,
                    pDelimiter IN VARCHAR2 DEFAULT ';',
                    pNullVal   IN VARCHAR2 DEFAULT 'n/a') RETURN VARCHAR2 IS
    sLine     VARCHAR2(2000);
    iStartPos INTEGER;
    iEndPos   INTEGER;
    iLength   INTEGER;
    vToken    VARCHAR2(200);
    bContinue BOOLEAN := TRUE;
  BEGIN
    -- Get start position
    IF (pPosition = 1) THEN
      iStartPos := 1;
    ELSIF (pPosition < 0) THEN
      iStartPos := INSTR(pString, pDelimiter, -1, ABS(pPosition)) + 1;
    ELSE
      iStartPos := INSTR(pString, pDelimiter, 1, pPosition - 1) + 1;
      IF (iStartPos = 1) THEN
        bContinue := FALSE;
      END IF;
    END IF;
  
    IF (bContinue) THEN
      -- Get the end position, and then the length of the token
      IF (pPosition > 0) THEN
        iEndPos := INSTR(pString, pDelimiter, 1, pPosition);
        IF (iEndPos > 0) THEN
          iLength := iEndPos - iStartPos;
        ELSIF (iEndPos = 0) THEN
          iLength := LENGTH(pString) - iStartPos + 1;
        END IF;
      ELSE
        IF (pPosition = -1) THEN
          iEndPos := LENGTH(pString);
        ELSE
          iEndPos := INSTR(pString, pDelimiter, -1, ABS(pPosition) - 1) - 1;
        END IF;
        iLength := iEndPos - iStartPos + 1;
      END IF;
    
      vToken := NVL(SUBSTR(pString, iStartPos, iLength), pNullVal);
    ELSE
      vToken := pNullVal;
    END IF;
  
    RETURN TO_CHAR(vToken);
  END getToken;

BEGIN
  vglNotesString := '2/5/2012;23412;Customer called reg. invoice#2/6/2012;23412;Contacted Lisa in the collection ';
  vglNotesString := vglNotesString ||
                    'department.#2/6/2012;23412;Compliance department have decided that customer ';
  vglNotesString := vglNotesString ||
                    'have sold products earlier on eBay. Customer''s status set to ON-HOLD. ';
  vglNotesString := vglNotesString || 'Waiting for further instruction';

  dbms_output.put_line('Positive tokenizing:');
  dbms_output.put_line('Note 1:[' ||
                       getToken(vglNotesString, 1, '#', 'n/a') || ']');
  dbms_output.put_line('Note 2:[' ||
                       getToken(vglNotesString, 2, '#', 'n/a') || ']');
  dbms_output.put_line('Note 3:[' ||
                       getToken(vglNotesString, 3, '#', 'n/a') || ']');
  dbms_output.put_line('Note 4:[' ||
                       getToken(vglNotesString, 4, '#', 'n/a') || ']');
  dbms_output.put_line(' -- ');
  dbms_output.put_line('Negative tokenizing:');
  dbms_output.put_line('Note -1:[' ||
                       getToken(vglNotesString, -1, '#', 'n/a') || ']');
  dbms_output.put_line('Note -2:[' ||
                       getToken(vglNotesString, -2, '#', 'n/a') || ']');
  dbms_output.put_line('Note -3:[' ||
                       getToken(vglNotesString, -3, '#', 'n/a') || ']');
  dbms_output.put_line('Note -4:[' ||
                       getToken(vglNotesString, -4, '#', 'n/a') || ']');
  dbms_output.put_line(' -- ');
  dbms_output.put_line('Positive tokenizing of a tokenized string:');
  dbms_output.put_line('Note 1:[' ||
                       getToken(getToken(vglNotesString, 1, '#', 'n/a'),
                                1,
                                ';',
                                'n/a') || ']');
  dbms_output.put_line('Note 2:[' ||
                       getToken(getToken(vglNotesString, 1, '#', 'n/a'),
                                2,
                                ';',
                                'n/a') || ']');
  dbms_output.put_line('Note 3:[' ||
                       getToken(getToken(vglNotesString, 1, '#', 'n/a'),
                                3,
                                ';',
                                'n/a') || ']');
END;
