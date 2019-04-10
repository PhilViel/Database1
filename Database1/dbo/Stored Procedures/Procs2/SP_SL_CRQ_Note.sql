/****************************************************************************************************
	Retourne la liste des notes d'un objet
 ******************************************************************************
	2004-06-01 Bruno Lapointe
		Création
 ******************************************************************************/
CREATE PROCEDURE [dbo].[SP_SL_CRQ_Note] (
	@NoteCodeID INTEGER, -- ID Unique de l'objet
	@NoteTypeClassName VARCHAR(75)) -- Type d'objet
AS
BEGIN
	SELECT
		N.NoteID,
		N.NoteTypeID,
		N.NoteCodeID,
		N.ConnectID,
		N.NoteText,
		NoteTypeClassName = UPPER(NT.NoteTypeClassName),
		NT.NoteTypeDesc,
		NT.NoteTypeLogText,
		NT.NoteTypeAllowObject
	FROM Mo_Note N
	JOIN Mo_NoteType NT ON (NT.NoteTypeID = N.NoteTypeID)
	WHERE N.NoteCodeID = @NoteCodeID
	  AND NT.NoteTypeClassName = @NoteTypeClassName 
	ORDER BY NT.NoteTypeDesc
END;
