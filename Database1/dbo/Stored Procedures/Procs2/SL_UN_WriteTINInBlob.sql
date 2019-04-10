/****************************************************************************************************
Copyrights (c) 2003 Gestion Universitas inc
Nom                 :	SL_UN_WriteTINInBlob
Description         :	Retourne l'objet Un_OperCancelation correspondant au OperID dans le blob du pointeur @pBlob 
								ou le champs texte @vcBlob.
Valeurs de retours  :	Type d’objet traité être dans le blob :
									Un_TIN
										OperID								INTEGER
										ExternalPlanID						INTEGER
										tiBnfRelationWithOtherConvBnf	TINYINT
										vcOtherConventionNo				VARCHAR(15)
										dtOtherConvention					DATETIME
										tiOtherConvBnfRelation			TINYINT
										bAIP									BIT
										bACESGPaid							BIT
										bBECInclud 							BIT
										bPGInclud							BIT
										fYearBnfCot							MONEY
										fBnfCot								MONEY
										fNoCESGCotBefore98				MONEY
										fNoCESGCot98AndAfter				MONEY
										fCESGCot								MONEY
										fCESG									MONEY
										fCLB									MONEY
										fAIP									MONEY
										fMarketValue						MONEY
										bPendingApplication				BIT
										ExternalPlanGovernmentRegNo	NVARCHAR(10)
										CompanyName							VARCHAR(75)
										Address								VARCHAR(75)
										City									VARCHAR(100)
										Statename							VARCHAR(75)
										CountryID							CHAR(4)
										CountryName							VARCHAR(75)
										ZipCode								VARCHAR(10)
								@ReturnValue :
									> 0 : Réussite
									<= 0 : Erreurs.
Note                :	ADX0000925	IA	2006-05-08	Bruno Lapointe		Création
*********************************************************************************************************************/
CREATE PROCEDURE [dbo].[SL_UN_WriteTINInBlob] (
	@OperID INTEGER, -- ID de l’opération de chèque
	@iBlobID INTEGER, -- ID du blob dans lequel on écrit
	@pBlob BINARY(16), -- Pointeur sur le blob
	@vcBlob VARCHAR(8000) OUTPUT, -- Contient le texte des objets à insérer dans le blob
	@iResult INTEGER OUTPUT ) -- Varible résultat
AS
BEGIN
	-- Un_TIN;OperID;ExternalPlanID;tiBnfRelationWithOtherConvBnf;vcOtherConventionNo;dtOtherConvention;tiOtherConvBnfRelation;
		-- bAIP;bACESGPaid;bBECInclud;fYearBnfCot;fBnfCot;fNoCESGCotBefore98;fNoCESGCot98AndAfter;fCESGCot;fCESG;fCLB;fAIP;fMarketValue;
		-- bPendingApplication;ExternalPlanGovernmentRegNo;CompanyName;Address;City;Statename;CountryID;CountryName;ZipCode;

	-- Traite les transferts IN
	IF EXISTS (
			SELECT OperID
			FROM Un_TIN
			WHERE OperID = @OperID) AND
		(@iResult > 0)
	BEGIN
		DECLARE
			@bCanReSend BIT

		IF NOT EXISTS (
			SELECT -- Pas d'enregistrement 400 valide
				O.OperID
			FROM Un_Oper O
			JOIN Un_Cotisation Ct ON Ct.OperID = O.OperID
			JOIN Un_CESP400 C4 ON C4.CotisationID = Ct.CotisationID
			LEFT JOIN Un_CESP400 R4 ON R4.iReversedCESP400ID = C4.iCESP400ID
			LEFT JOIN Un_CESP900 C9 ON C9.iCESP400ID = C4.iCESP400ID AND C9.tiCESP900OriginID = 3 -- Transaction 900 dont l'origine n'est pas transfert non-réglé
			WHERE O.OperID = @OperID
				AND R4.iCESP400ID IS NULL
				AND C9.iCESP900ID IS NULL
				AND C4.iCESP800ID IS NULL
				AND C4.iReversedCESP400ID IS NULL
				)
			SET @bCanReSend = 1
		ELSE
			SET @bCanReSend = 0

		-- Si Il n'y pas assez d'espace disponible dans la variable, on inscrit le contenu de la variable dans le blob et on vide la variable par la suite
		IF LEN(@vcBlob) > 7000
		BEGIN
			DECLARE
				@iBlobLength INTEGER

			SELECT @iBlobLength = DATALENGTH(txBlob)
			FROM CRI_Blob
			WHERE iBlobID = @iBlobID

			UPDATETEXT CRI_Blob.txBlob @pBlob @iBlobLength 0 @vcBlob 

			IF @@ERROR <> 0
				SET @iResult = -11

			SET @vcBlob = ''
		END

		-- Inscrit les données du transfert IN de l'opération dans le blob
		SELECT 
			@vcBlob = 
				@vcBlob +
				'Un_TIN;'+
				CAST(@OperID AS VARCHAR)+';'+
				CAST(T.ExternalPlanID AS VARCHAR)+';'+
				CAST(T.tiBnfRelationWithOtherConvBnf AS VARCHAR)+';'+
				T.vcOtherConventionNo+';'+
				CONVERT(CHAR(10), T.dtOtherConvention, 20)+';'+
				CAST(ISNULL(T.tiOtherConvBnfRelation,0) AS VARCHAR)+';'+
				CAST(T.bAIP AS VARCHAR)+';'+
				CAST(T.bACESGPaid AS VARCHAR)+';'+
				CAST(T.bBECInclud AS VARCHAR)+';'+
				CAST(T.bPGInclud AS VARCHAR)+';'+
				CAST(T.fYearBnfCot AS VARCHAR)+';'+
				CAST(T.fBnfCot AS VARCHAR)+';'+
				CAST(T.fNoCESGCotBefore98 AS VARCHAR)+';'+
				CAST(T.fNoCESGCot98AndAfter AS VARCHAR)+';'+
				CAST(T.fCESGCot AS VARCHAR)+';'+
				CAST(T.fCESG AS VARCHAR)+';'+
				CAST(T.fCLB AS VARCHAR)+';'+
				CAST(T.fAIP AS VARCHAR)+';'+
				CAST(T.fMarketValue AS VARCHAR)+';'+
				CAST(T.bPendingApplication AS VARCHAR)+';'+
				P.ExternalPlanGovernmentRegNo+';'+
				C.CompanyName+';'+
				ISNULL(A.Address,'')+';'+
				ISNULL(A.City,'')+';'+
				ISNULL(A.Statename,'')+';'+
				ISNULL(A.CountryID,'')+';'+
				ISNULL(Cn.CountryName,'')+';'+
				ISNULL(A.ZipCode,'')+';'+
				CAST(@bCanReSend AS VARCHAR)+';'+
				CHAR(13)+CHAR(10)
		FROM Un_TIN T
		JOIN Un_ExternalPlan P ON P.ExternalPlanID = T.ExternalPlanID
		JOIN Mo_Company C ON C.CompanyID = P.ExternalPromoID
		LEFT JOIN Mo_Dep D ON D.CompanyID = C.CompanyID
		LEFT JOIN dbo.Mo_Adr A ON A.AdrID = D.AdrID		
		LEFT JOIN Mo_Country Cn ON Cn.CountryID = A.CountryID
		WHERE OperID = @OperID
	END

	RETURN @iResult
END


