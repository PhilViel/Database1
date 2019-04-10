/****************************************************************************************************
Copyrights (c) 2003 Gestion Universitas inc
Nom                 :	SL_UN_WriteOUTInBlob
Description         :	Retourne l'objet Un_OperCancelation correspondant au OperID dans le blob du pointeur @pBlob 
								ou le champs texte @vcBlob.
Valeurs de retours  :	Type d’objet traité être dans le blob :
									Un_OUT
										OperID	INTEGER
										ExternalPlanID	INTEGER
										tiBnfRelationWithOtherConvBnf	TINYINT
										vcOtherConventionNo	VARCHAR(15)
										tiREEEType	TINYINT
										bEligibleForCESG	BIT
										bEligibleForCLB	BIT
										bOtherContratBnfAreBrothers	BIT
										fYearBnfCot	MONEY
										fBnfCot	MONEY
										fNoCESGCotBefore98	MONEY
										fNoCESGCot98AndAfter	MONEY
										fCESGCot	MONEY
										fCESG	MONEY
										fCLB	MONEY
										fAIP	MONEY
										fMarketValue	MONEY
										ExternalPlanGovernmentRegNo	NVARCHAR(10)
										CompanyName	VARCHAR(75)
										Address	VARCHAR(75)
										City	VARCHAR(100)
										Statename	VARCHAR(75)
										CountryID	CHAR(4)
										CountryName	VARCHAR(75)
										ZipCode	VARCHAR(10)						
								@ReturnValue :
									> 0 : Réussite
									<= 0 : Erreurs.
Note                :	ADX0000922	IA	2006-05-23	Alain Quirion		Création
*********************************************************************************************************************/
CREATE PROCEDURE [dbo].[SL_UN_WriteOUTInBlob] (
	@OperID INTEGER, -- ID de l’opération de chèque
	@iBlobID INTEGER, -- ID du blob dans lequel on écrit
	@pBlob BINARY(16), -- Pointeur sur le blob
	@vcBlob VARCHAR(8000) OUTPUT, -- Contient le texte des objets à insérer dans le blob
	@iResult INTEGER OUTPUT ) -- Varible résultat
AS
BEGIN
	-- Un_OUT;OperID;ExternalPlanID;tiBnfRelationWithOtherConvBnf;vcOtherConventionNo;tiREEEType;
		--bEligibleForCESG;bEligibleForCLB;bOtherContratBnfAreBrothers;fYearBnfCot;fBnfCot;fNoCESGCotBefore98;
		--fNoCESGCot98AndAfter;fCESGCot;fCESG;fCLB;fAIP;fMarketValue;ExternalPlanGovernmentRegNo;CompanyName;
		--Address;City;Statename;CountryID;CountryName;ZipCode

	-- Traite les transferts OUT
	IF EXISTS (
			SELECT OperID
			FROM Un_OUT
			WHERE OperID = @OperID) AND
		(@iResult > 0)
	BEGIN
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

		-- Inscrit les données du transfert OUT de l'opération dans le blob
		SELECT 
			@vcBlob = 
				@vcBlob +
				'Un_OUT;'+
				CAST(@OperID AS VARCHAR)+';'+
				CAST(T.ExternalPlanID AS VARCHAR)+';'+
				CAST(T.tiBnfRelationWithOtherConvBnf AS VARCHAR)+';'+
				T.vcOtherConventionNo+';'+
				CAST(ISNULL(T.tiREEEType,0) AS VARCHAR)+';'+
				CAST(T.bEligibleForCESG AS VARCHAR)+';'+
				CAST(T.bEligibleForCLB AS VARCHAR)+';'+
				CAST(T.bOtherContratBnfAreBrothers AS VARCHAR)+';'+
				CAST(T.fYearBnfCot AS VARCHAR)+';'+
				CAST(T.fBnfCot AS VARCHAR)+';'+
				CAST(T.fNoCESGCotBefore98 AS VARCHAR)+';'+
				CAST(T.fNoCESGCot98AndAfter AS VARCHAR)+';'+
				CAST(T.fCESGCot AS VARCHAR)+';'+
				CAST(T.fCESG AS VARCHAR)+';'+
				CAST(T.fCLB AS VARCHAR)+';'+
				CAST(T.fAIP AS VARCHAR)+';'+
				CAST(T.fMarketValue AS VARCHAR)+';'+
				P.ExternalPlanGovernmentRegNo+';'+
				C.CompanyName+';'+
				ISNULL(A.Address,'')+';'+
				ISNULL(A.City,'')+';'+
				ISNULL(A.Statename,'')+';'+
				ISNULL(A.CountryID,'')+';'+
				ISNULL(Cn.CountryName,'')+';'+
				ISNULL(A.ZipCode,'')+';'+
				CHAR(13)+CHAR(10)
		FROM Un_OUT T
		JOIN Un_ExternalPlan P ON P.ExternalPlanID = T.ExternalPlanID
		JOIN Mo_Company C ON C.CompanyID = P.ExternalPromoID
		LEFT JOIN Mo_Dep D ON D.CompanyID = C.CompanyID
		LEFT JOIN dbo.Mo_Adr A ON A.AdrID = D.AdrID		
		LEFT JOIN Mo_Country Cn ON Cn.CountryID = A.CountryID
		WHERE OperID = @OperID
	END

	RETURN @iResult
END


