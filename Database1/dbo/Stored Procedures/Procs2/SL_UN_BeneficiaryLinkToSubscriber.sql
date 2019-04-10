/****************************************************************************************************
Copyrights (c) 2003 Gestion Universitas inc
Nom                : SL_UN_BeneficiaryLinkToSubscriber
Description        : Retourne les bénéficiaires d'un souscripteur et leurs adresses.
Valeurs de retours : Dataset de donn‚es
Note               :	ADX0000323	IA	2004-09-29	Bruno Lapointe			Création (10.02.02)
						ADX0000831	IA	2006-03-20	Bruno Lapointe			Adaptation des conventions pour PCEE 4.3
										2009-05-26	Jean-François Gauthier	Ajout du champ BirthDate
										2010-02-05	Jean-François Gauthier	Correction des accents dans les commentaires		
****************************************************************************************************/
CREATE PROCEDURE [dbo].[SL_UN_BeneficiaryLinkToSubscriber] (
	@SubscriberID INTEGER) -- ID Unique du souscripteur
AS
BEGIN
	SELECT 
		H.LastName,							-- Nom du bénéficiaire
		H.FirstName,						-- Prénom du bénéficiaire
		B.BeneficiaryID,					-- ID Unique du bénéficiaire
		Address = ISNULL(A.Address,''),		-- No. Civique, rue et appartement du bénéficiaire
		City = ISNULL(A.City,''),			-- Ville du bénéficiaire
		Statename = ISNULL(A.Statename,''), -- Province du bénéficiaire
		ZipCode = ISNULL(A.ZipCode,''),		-- Code postal du bénéficiaire
		Phone1 = ISNULL(A.Phone1,''),		-- Téléphone à la maison du bénéficiaire
		RT.tiRelationshipTypeID,			-- Lien entre le souscripteur et le bénéficiaire
		RT.vcRelationshipType,				-- Lien entre le souscripteur et le bénéficiaire
		H.BirthDate
	FROM (									-- Retourne tout les bénéficiaires du souscripteur et le plus petit lien de parenté qui les unis.
		SELECT 
			C.BeneficiaryID,
			tiRelationshipTypeID = MIN(C.tiRelationshipTypeID)
		FROM dbo.Un_Convention C
		JOIN Un_RelationshipType RT ON RT.tiRelationshipTypeID = C.tiRelationshipTypeID
		WHERE C.SubscriberID = @SubscriberID
		GROUP BY C.BeneficiaryID
		) V
		JOIN dbo.Un_Beneficiary B ON B.BeneficiaryID = V.BeneficiaryID
		JOIN dbo.Mo_Human H ON H.HumanID = B.BeneficiaryID
		JOIN Un_RelationshipType RT ON RT.tiRelationshipTypeID = V.tiRelationshipTypeID
		LEFT JOIN dbo.Mo_Adr A ON A.AdrID = H.AdrID
	ORDER BY 
		H.LastName,
		H.FirstName,
		A.Address,
		A.City,
		A.Statename,
		A.ZipCode,
		A.Phone1,
		B.BeneficiaryID
END


