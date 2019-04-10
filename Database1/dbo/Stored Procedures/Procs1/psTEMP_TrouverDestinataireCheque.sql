/****************************************************************************************************
Copyrights (c) 2008 Gestion Universitas inc.

Code du service		: psTEMP_TrouverDestinataireCheque
Nom du service		: 
But 				: Retrouver un destinaire de chèque (déjà utilisé) à partir de l'outil de changement de destinaire
Facette				: TEMP

Paramètres d’entrée	:	Paramètre					Description
						--------------------------	-----------------------------------------------------------------

Exemple d’appel		:	

Paramètres de sortie:	

Historique des modifications:
		Date			Programmeur							Description									Référence
		------------	----------------------------------	-----------------------------------------	------------
		2016-04-29		Donald Huppé						Création du service		


EXEC psTEMP_TrouverDestinataireCheque 'pierre roy', 'H2X 3J7'
EXEC psTEMP_TrouverDestinataireCheque NULL, 'H2X3J7'
EXEC psTEMP_TrouverDestinataireCheque 'pierre roy', NULL
EXEC psTEMP_TrouverDestinataireCheque NULL, NULL

****************************************************************************************************/
CREATE PROCEDURE [dbo].[psTEMP_TrouverDestinataireCheque] 
(
	@cNomDestinataire VARCHAR(250) = null,
	@cCodePostal VARCHAR(10) = null

)
AS
BEGIN

	SET @cCodePostal = REPLACE( REPLACE(@cCodePostal,' ',''), '-','')

	SELECT 
		h.HumanID, 
		NomDestinataire =  ltrim(rtrim(H.FirstName + ' '+ h.LastName)),
		Adresse = a.Address,
		Ville = a.City,
		CodePostal = dbo.fn_Mo_FormatZIP( a.ZipCode,a.CountryID),
		Province = a.StateName
	FROM 
		CHQ_Payee p
		JOIN Mo_Human h on p.iPayeeID = h.HumanID
		JOIN Mo_Adr a on h.AdrID = a.AdrID
	WHERE 
		(h.LastName + ' ' + h.LastName LIKE '%' + @cNomDestinataire + '%' or isnull(@cNomDestinataire,'') = '' ) --'%pierre roy%'
		AND 
		(a.ZipCode LIKE '%' + @cCodePostal + '%' OR isnull(@cCodePostal,'') = '' )
		AND 
		(isnull(@cNomDestinataire,'') <> '' OR isnull(@cCodePostal,'') <> '')
		AND ltrim(rtrim(H.FirstName + ' '+ h.LastName)) <> ''


END
