/****************************************************************************************************
	Liste des textes de diplômes
 ******************************************************************************
	2004-08-20	Bruno Lapointe			Création
	2015-08-04	Pierre-Luc Simard		Ne plus retourner la liste à Delphi car il y a un bug depuis l'utilisation du TexteDiplome directement dans la table Un_Convention.
 ******************************************************************************/
CREATE PROCEDURE [dbo].[SP_SL_UN_DiplomaText] (
	@Visible BIT = 0) -- Si la liste doit avoir les textes de diplôme qui ne sont plus disponible à l'ajout modification de conventions
AS
BEGIN
	SELECT
		DiplomaTextID,
		DiplomaText,
		VisibleInList
	FROM Un_DiplomaText
	WHERE VisibleInList <> 0
		OR @Visible <> 0
	ORDER BY DiplomaText
END

