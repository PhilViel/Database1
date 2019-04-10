/****************************************************************************************************
	Liste des types de notes
 ******************************************************************************
	2004-06-01 Bruno Lapointe
		Création
	2004-08-25 Bruno Lapointe
		Exclusion des types de notes invisibles si on donne la liste pour un 
		objet.
		Bug report ADX0001012
 ******************************************************************************/
CREATE PROCEDURE [dbo].[SP_SL_CRQ_NoteType] (
	@NoteTypeClassName VARCHAR(75))
AS
BEGIN
	IF @NoteTypeClassName = 'OBJ' -- Donne la liste des types d'objet
		SELECT DISTINCT NoteTypeClassName
		FROM Mo_NoteType
	ELSE IF (@NoteTypeClassName = 'ALL') OR (@NoteTypeClassName IS NULL) 
		-- Donne la liste de tout les types de notes
		SELECT *
		FROM Mo_NoteType
	ELSE
		-- Donne la liste des types notes d'un objet
		SELECT
			T.NoteTypeID,
			T.NoteTypeClassName,
			T.NoteTypeDesc,
			T.NoteTypeLogText,
			T.NoteTypeAllowObject
		FROM Mo_NoteType T
		WHERE @NoteTypeClassName = T.NoteTypeClassName
		  AND T.NoteTypeVisible <> 0
		ORDER BY T.NoteTypeClassName, T.NoteTypeDesc
END;
