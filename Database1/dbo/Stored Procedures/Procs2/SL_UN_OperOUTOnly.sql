/****************************************************************************************************
Copyrights (c) 2003 Gestion Universitas inc
Nom                 :	SL_UN_OperOUTOnly
Description         :	Retourne tout les champs d'un OUT uniquement.
Valeurs de retours  :	Dataset :								
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
					> 0 : Réussite : ID du blob qui contient les objets
					<= 0 : Erreurs.
Note                :	ADX0000992	IA	2006-05-31	Alain Quirion		Création
*********************************************************************************************************************/
CREATE PROCEDURE [dbo].[SL_UN_OperOUTOnly] (
	@OperID INTEGER ) -- ID de l’opération de transfert de out
AS
BEGIN
	-- Un_OUT;OperID;ExternalPlanID;tiBnfRelationWithOtherConvBnf;vcOtherConventionNo;tiREEEType;bEligibleForCESG;bEligibleForCLB;bOtherContratBnfAreBrothers;fYearBnfCot;fBnfCot;fNoCESGCotBefore98;fNoCESGCot98AndAfter;fCESGCot;fCESG;fCLB;fAIP;fMarketValue;ExternalPlanGovernmentRegNo;CompanyName;Address;City;Statename;CountryID;CountryName;ZipCode
	DECLARE @iResult INTEGER
	
	-- Valide que la liste de IDs n'est pas vide
	IF NOT EXISTS (
			SELECT OperID
			FROM Un_OUT
			WHERE OperID = @OperID )
		SET @iResult = -1 -- Pas d'opération
	ELSE
	BEGIN
		SELECT
			OperID,
			T.ExternalPlanID,
			T.tiBnfRelationWithOtherConvBnf,
			T.vcOtherConventionNo,
			T.tiREEEType,
			T.bEligibleForCESG,
			T.bEligibleForCLB,
			T.bOtherContratBnfAreBrothers,
			T.fYearBnfCot,
			T.fBnfCot,
			T.fNoCESGCotBefore98,
			T.fNoCESGCot98AndAfter,
			T.fCESGCot,
			T.fCESG,
			T.fCLB,
			T.fAIP,
			T.fMarketValue,
			P.ExternalPlanGovernmentRegNo,
			C.CompanyName,
			A.Address,
			A.City,
			A.Statename,
			A.CountryID,
			Cn.CountryName,
			A.ZipCode	
		FROM Un_OUT T
		JOIN Un_ExternalPlan P ON P.ExternalPlanID = T.ExternalPlanID
		JOIN Mo_Company C ON C.CompanyID = P.ExternalPromoID
		LEFT JOIN Mo_Dep D ON D.CompanyID = C.CompanyID
		LEFT JOIN dbo.Mo_Adr A ON A.AdrID = D.AdrID		
		LEFT JOIN Mo_Country Cn ON Cn.CountryID = A.CountryID
		WHERE OperID = @OperID

		IF @@ERROR <> 0 
			SET @iResult = 1
											
	END

	RETURN @iResult
END


