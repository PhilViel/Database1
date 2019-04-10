/****************************************************************************************************
Copyrights (c) 2003 Gestion Universitas inc
Nom                 :	SL_UN_SubscriberOfBeneficiary
Description         :	Procédure retournant la liste des souscripteurs d’un bénéficiaire.
Valeurs de retours  :	Dataset :
									SubscriberID		INTEGER		ID du souscripteur, correspond au HumanID.
									FirstName			VARCHAR(35)	Prénom du souscripteur
									LastName				VARCHAR(50)	Nom du souscripteur
									SocialNumber		VARCHAR(75)	NAS ou NE du souscripteur
									IsCompany			BIT			Indique si le souscripteur est une compagnie.
									Address				VARCHAR(75)	Adresse
									City					VARCHAR(100)Ville
									Statename			VARCHAR(75)	Province
									ZipCode				VARCHAR(10)	Code postal
									Phone1				VARCHAR(27) Téléphone résidentiel
Note                :	ADX0000692	IA	2005-05-04	Bruno Lapointe		Création
								ADX0000798	IA	2006-03-21	Bruno Lapointe		Saisie des principaux responsables
*********************************************************************************************************************/
CREATE PROCEDURE [dbo].[SL_UN_SubscriberOfBeneficiary] (
	@BeneficiaryID INTEGER ) -- ID unique du bénéficiaire dont on veut les souscripteur
AS
BEGIN
	SELECT DISTINCT
		C.SubscriberID,
		S.FirstName,
		S.LastName,
		S.SocialNumber,
		S.IsCompany,
		Address = ISNULL(A.Address, ''),
		City = ISNULL(A.City, ''),
		Statename = ISNULL(A.Statename, ''),
		ZipCode = ISNULL(A.ZipCode, ''),
		Phone1 = ISNULL(A.Phone1, '')
	FROM dbo.Un_Convention C
	JOIN dbo.Mo_Human S ON S.HumanID = C.SubscriberID
	LEFT JOIN dbo.Mo_Adr A ON A.AdrID = S.AdrID
	WHERE C.BeneficiaryID = @BeneficiaryID
END


