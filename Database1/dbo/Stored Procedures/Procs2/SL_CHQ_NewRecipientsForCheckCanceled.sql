/****************************************************************************************************
Copyrights (c) 2003 Compurangers.inc
Nom                 :	SL_CHQ_NewRecipientsForCheckCanceled
Description         :	Procédure qui retourne la liste des destinataires disponibles lors d’une « Annulation : Destinataire perdu ».
Valeurs de retours  :	Dataset :
				HumanID		INTEGER		ID de l’humain (souscripteur, bénéficiaire ou destinataire).
				Tablename	VARCHAR(75)	Nom de la table qui permet de définir le type de destinataire dont il s’agit (Un_Subscriber = souscripteur, Un_Beneficiary = bénéficiaire, Un_Recipient = destinataire)
				FirstName	VARCHAR(35)	Prénom du destinataire
				LastName	VARCHAR(50)	Nom
				Address		VARCHAR(75)	# civique, rue et # d’appartement.
				ZipCode		VARCHAR(10)	Code postal
				Phone1		VARCHAR(27)	Tél. résidence
				
Note                :	ADX0001179	IA	2006-10-25	Alain Quirion		Création
*********************************************************************************************************************/
CREATE PROCEDURE [dbo].[SL_CHQ_NewRecipientsForCheckCanceled]
AS
BEGIN
	SELECT * 
	FROM	(SELECT 
			HumanID = H.HumanID,
			TableName = 'Un_Subscriber',
			FirstName = H.FirstName,
			LastName = H.LastName,
			Address = ISNULL(A.Address,''),
			City = ISNULL(A.City,''),
			StateName = ISNULL(A.StateName,''),
			ZipCode = ISNULL(A.ZipCode,''),
			Phone1 = ISNULL(A.Phone1,''),
			bIsCompany = H.IsCompany
		FROM CHQ_NewRecipientsForCheckCanceled C
		JOIN dbo.Mo_Human H ON H.HumanID = C.iRecipientID
		JOIN dbo.Un_Subscriber S ON S.SubscriberID = H.HumanID
		LEFT JOIN dbo.Mo_Adr A ON H.AdrID = A.AdrID
		-----
		UNION
		-----
		SELECT 
			HumanID = H.HumanID,
			TableName = 'Un_Beneficiary',
			FirstName = H.FirstName,
			LastName = H.LastName,
			Address = ISNULL(A.Address,''),
			City = ISNULL(A.City,''),
			StateName = ISNULL(A.StateName,''),
			ZipCode = ISNULL(A.ZipCode,''),
			Phone1 = ISNULL(A.Phone1,''),
			bIsCompany = H.IsCompany
		FROM CHQ_NewRecipientsForCheckCanceled C
		JOIN dbo.Mo_Human H ON H.HumanID = C.iRecipientID
		JOIN dbo.Un_Beneficiary B ON B.BeneficiaryID = H.HumanID
		LEFT JOIN dbo.Mo_Adr A ON H.AdrID = A.AdrID
		-----
		UNION
		-----
		SELECT 
			HumanID = H.HumanID,
			TableName = 'Un_Recipient',
			FirstName = H.FirstName,
			LastName = H.LastName,
			Address = ISNULL(A.Address,''),
			City = ISNULL(A.City,''),
			StateName = ISNULL(A.StateName,''),
			ZipCode = ISNULL(A.ZipCode,''),
			Phone1 = ISNULL(A.Phone1,''),
			bIsCompany = H.IsCompany
		FROM CHQ_NewRecipientsForCheckCanceled C
		JOIN dbo.Mo_Human H ON H.HumanID = C.iRecipientID
		JOIN Un_Recipient R ON R.iRecipientID = H.HumanID
		LEFT JOIN dbo.Mo_Adr A ON H.AdrID = A.AdrID) G
	ORDER BY G.LastName, G.FirstName, G.Address
END


