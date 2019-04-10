
/****************************************************************************************************
Copyrights (c) 2008 Gestion Universitas inc.

Code du service	: psTEMP_ObtenirCorrectionARI
Nom du service		: 
But 				: 
Facette			: TEMP

Paramètres d’entrée	:	Paramètre					Description
					--------------------------	-----------------------------------------------------------------

Exemple d’appel	:	
    exec psTEMP_ObtenirCorrectionARI @vcConventionNo = '1235632', @dtEndateDu = '2013-03-25'

Paramètres de sortie:	

Historique des modifications:
    Date        Programmeur             Description
    ----------  --------------------    -----------------------------------------------------
    2013-03-28  Donald Huppé            Création du service		
    2014-03-21  Donald Huppé            Transférer table GUI.tblOrdreAttributionPerteARI vers UnivBase.tblOPER_OrdreAttributionPerteARI
                                        Et modififier cette sp en conséquence
    2016-06-01  Dominique Pothier       Deprecated - Cette stored proc ne devrait plus être utilisée
                                        Les fonctionnalités de cette stored proc ont étées ramenées dans GUI.Application.Finances.Ari. 
	2018-06-18	Donald Huppé			La ps est toujours utilisé depuis le message Deprecated précédent
										--> Modification du calcul des corrections suite au cas du ARI de x-20170817001 le 2018-06-18
****************************************************************************************************/
CREATE PROCEDURE [dbo].[psTEMP_ObtenirCorrectionARI] 
(
	
	@vcConventionNo VARCHAR(15),
	@dtEndateDu	datetime
)
AS
BEGIN

	declare
	
	@FaireARI int,
	
	@i int,
	
	@INM MONEY,
	@ITR MONEY,
	@INS MONEY,
	@ISPlus MONEY,
	@IBC MONEY,
	@IST MONEY,
	@MIM MONEY,
	@ICQ MONEY,
	@IMQ MONEY,
	@III MONEY,
	@IIQ MONEY,
	@IQI MONEY,
	@EAFB MONEY,
	
	@INM_c MONEY,
	@ITR_c MONEY,
	@INS_c MONEY,
	@ISPlus_c MONEY,
	@IBC_c MONEY,
	@IST_c MONEY,
	@MIM_c MONEY,
	@ICQ_c MONEY,
	@IMQ_c MONEY,
	@III_c MONEY,
	@IIQ_c MONEY,
	@IQI_c MONEY,
	@EAFB_c MONEY,
	
	@Compte varchar(6),
	@Solde money,
	@SoldeLeftToFind money,
	
	@iID_Convention INT,
	@dtDateOperARI DATETIME,
	@iID_Operation INT

	set @INM_c = 0.0
	set @ITR_c = 0.0
	set @INS_c  = 0.0
	set @ISPlus_c  = 0.0
	set @IBC_c  = 0.0
	set @IST_c  = 0.0
	set @MIM_c  = 0.0
	set @ICQ_c  = 0.0
	set @IMQ_c  = 0.0
	set @III_c  = 0.0
	set @IIQ_c  = 0.0
	set @IQI_c  = 0.0
	set @EAFB_c  = 0.0

	--SET @vcConventionNo = '1235632' --'1541393'-- 'T-20121101617' -
	
	SET @dtDateOperARI = @dtEndateDu --LEFT(CONVERT(VARCHAR, getdate(), 120), 10)

	SELECT @iID_Convention = C.ConventionID
	FROM dbo.Un_Convention C
	WHERE C.ConventionNo = @vcConventionNo
	
	SELECT 
		--c.ConventionNo,
		@INM = sum(CASE WHEN co.ConventionOperTypeID = 'INM' THEN co.ConventionOperAmount ELSE 0 END),
		@ITR = sum(CASE WHEN co.ConventionOperTypeID = 'ITR' THEN co.ConventionOperAmount ELSE 0 END),
		@INS = sum(CASE WHEN co.ConventionOperTypeID = 'INS' THEN co.ConventionOperAmount ELSE 0 END),
		@ISPlus = sum(CASE WHEN co.ConventionOperTypeID = 'IS+' THEN co.ConventionOperAmount ELSE 0 END),
		@IBC = sum(CASE WHEN co.ConventionOperTypeID = 'IBC' THEN co.ConventionOperAmount ELSE 0 END),
		@IST = sum(CASE WHEN co.ConventionOperTypeID = 'IST' THEN co.ConventionOperAmount ELSE 0 END),
		@MIM = sum(CASE WHEN co.ConventionOperTypeID = 'MIM' THEN co.ConventionOperAmount ELSE 0 END),
		@ICQ = sum(CASE WHEN co.ConventionOperTypeID = 'ICQ' THEN co.ConventionOperAmount ELSE 0 END),
		@IMQ = sum(CASE WHEN co.ConventionOperTypeID = 'IMQ' THEN co.ConventionOperAmount ELSE 0 END),
		@III = sum(CASE WHEN co.ConventionOperTypeID = 'III' THEN co.ConventionOperAmount ELSE 0 END),
		@IIQ = sum(CASE WHEN co.ConventionOperTypeID = 'IIQ' THEN co.ConventionOperAmount ELSE 0 END),
		@IQI = sum(CASE WHEN co.ConventionOperTypeID = 'IQI' THEN co.ConventionOperAmount ELSE 0 END)
	from 
		Un_Convention c
		JOIN Un_ConventionOper co ON c.Conventionid = co.ConventionID
		JOIN Un_Oper o ON co.OperID = o.OperID
	WHERE 
		c.ConventionNo = @vcConventionNo
		AND o.OperDate <= @dtEndateDu
	GROUP by 
		c.ConventionNo
		
	DECLARE @tblSolde table (cpt varchar(6), solde money)	
	INSERT into @tblSolde values ('INM',@INM )
	INSERT into @tblSolde values ('ITR',@ITR )
	INSERT into @tblSolde values ('INS',@INS )
	INSERT into @tblSolde values ('ISPLus',@ISPlus )
	INSERT into @tblSolde values ('IBC',@IBC )
	INSERT into @tblSolde values ('IST',@IST )
	INSERT into @tblSolde values ('ICQ',@ICQ )
	INSERT into @tblSolde values ('MIM',@MIM )
	INSERT into @tblSolde values ('IIQ',@IIQ )
	INSERT into @tblSolde values ('IMQ',@IMQ )
	INSERT into @tblSolde values ('IQI',@IQI )
	INSERT into @tblSolde values ('III',@III )	
	
	--SELECT * from @tblSolde

	--set @INM = -158
	
	IF @INM < 0
		begin
		
		set @inm_c = abs(@INM)
		set @SoldeLeftToFind = abs(@INM)
		
		set @i = 1
		while @i <= 12 and @SoldeLeftToFind > 0 --abs(@inm_c) <> abs(@INM)
			begin
			select 
				@Solde = solde ,
				@Compte = cpt
			from 
				@tblSolde 
			where 
				cpt = (select inm from tblOPER_OrdreAttributionPerteARI A where A.Ordre = @i)
	
			if @Solde > 0 
				begin
				
				update @tblSolde 
				set 
					solde = case 
							when @Solde >= @SoldeLeftToFind then solde - @SoldeLeftToFind 
							ELSE 0
							end
				where cpt = (select inm from tblOPER_OrdreAttributionPerteARI A where A.Ordre = @i)

				--print @Compte + ' ' + cast(@SoldeLeftToFind as varchar(10))
				--print @Solde
				
				IF @Compte = 'INM' AND @INM + @INM_c > 0			set @INM_c = @INM_c -		case when @SoldeLeftToFind < @Solde THEN @SoldeLeftToFind ELSE @Solde end
				IF @Compte = 'ITR' AND @ITR + @ITR_c > 0			set @ITR_c = @ITR_c -		case when @SoldeLeftToFind < @Solde THEN @SoldeLeftToFind ELSE @Solde end
				IF @Compte = 'INS' AND @INS + @INS_c > 0			set @INS_c = @INS_c -		case when @SoldeLeftToFind < @Solde THEN @SoldeLeftToFind ELSE @Solde end
				IF @Compte = 'ISPLUS' AND @ISPlus + @ISPlus_c > 0	set @ISPlus_c = @ISPlus_c - case when @SoldeLeftToFind < @Solde THEN @SoldeLeftToFind ELSE @Solde end
				IF @Compte = 'IBC' AND @IBC + @IBC_c > 0			set @IBC_c = @IBC_c -		case when @SoldeLeftToFind < @Solde THEN @SoldeLeftToFind ELSE @Solde end
				IF @Compte = 'IST' AND @IST + @IST_c > 0			set @IST_c = @IST_c -		case when @SoldeLeftToFind < @Solde THEN @SoldeLeftToFind ELSE @Solde end
				IF @Compte = 'MIM' AND @MIM + @MIM_c > 0			set @MIM_c = @MIM_c -		case when @SoldeLeftToFind < @Solde THEN @SoldeLeftToFind ELSE @Solde end
				IF @Compte = 'ICQ' AND @ICQ + @ICQ_c > 0			set @ICQ_c = @ICQ_c -		case when @SoldeLeftToFind < @Solde THEN @SoldeLeftToFind ELSE @Solde end
				IF @Compte = 'IMQ' AND @IMQ + @IMQ_c > 0			set @IMQ_c = @IMQ_c -		case when @SoldeLeftToFind < @Solde THEN @SoldeLeftToFind ELSE @Solde end
				IF @Compte = 'III' AND @III + @III_c > 0			set @III_c = @III_c -		case when @SoldeLeftToFind < @Solde THEN @SoldeLeftToFind ELSE @Solde end
				IF @Compte = 'IIQ' AND @IIQ + @IIQ_c > 0			set @IIQ_c = @IIQ_c -		case when @SoldeLeftToFind < @Solde THEN @SoldeLeftToFind ELSE @Solde end
				IF @Compte = 'IQI' AND @IQI + @IQI_c > 0			set @IQI_c = @IQI_c -		case when @SoldeLeftToFind < @Solde THEN @SoldeLeftToFind ELSE @Solde end
			
				set @SoldeLeftToFind = case 
										WHEN @Solde >= @SoldeLeftToFind then 0
										else @SoldeLeftToFind - @Solde
										end
		
				end

			set @i = @i + 1
			end
	
		end
	
	IF @ITR < 0
		begin
		
		set @ITR_c = abs(@ITR)
		set @SoldeLeftToFind = abs(@ITR)
		
		set @i = 1
		while @i <= 12 and @SoldeLeftToFind > 0 --abs(@inm_c) <> abs(@INM)
			begin
			select 
				@Solde = solde ,
				@Compte = cpt
			from 
				@tblSolde 
			where 
				cpt = (select ITR from tblOPER_OrdreAttributionPerteARI A where A.Ordre = @i)
	
			if @Solde > 0 
				begin
				
				update @tblSolde 
				set 
					solde = case 
							when @Solde >= @SoldeLeftToFind then solde - @SoldeLeftToFind 
							ELSE 0
							end
				where cpt = (select ITR from tblOPER_OrdreAttributionPerteARI A where A.Ordre = @i)

				--print @Compte + ' ' + cast(@SoldeLeftToFind as varchar(10))
				--print @Solde
				
				IF @Compte = 'INM' AND @INM + @INM_c > 0			set @INM_c = @INM_c -		case when @SoldeLeftToFind < @Solde THEN @SoldeLeftToFind ELSE @Solde end
				IF @Compte = 'ITR' AND @ITR + @ITR_c > 0			set @ITR_c = @ITR_c -		case when @SoldeLeftToFind < @Solde THEN @SoldeLeftToFind ELSE @Solde end
				IF @Compte = 'INS' AND @INS + @INS_c > 0			set @INS_c = @INS_c -		case when @SoldeLeftToFind < @Solde THEN @SoldeLeftToFind ELSE @Solde end
				IF @Compte = 'ISPLUS' AND @ISPlus + @ISPlus_c > 0	set @ISPlus_c = @ISPlus_c - case when @SoldeLeftToFind < @Solde THEN @SoldeLeftToFind ELSE @Solde end
				IF @Compte = 'IBC' AND @IBC + @IBC_c > 0			set @IBC_c = @IBC_c -		case when @SoldeLeftToFind < @Solde THEN @SoldeLeftToFind ELSE @Solde end
				IF @Compte = 'IST' AND @IST + @IST_c > 0			set @IST_c = @IST_c -		case when @SoldeLeftToFind < @Solde THEN @SoldeLeftToFind ELSE @Solde end
				IF @Compte = 'MIM' AND @MIM + @MIM_c > 0			set @MIM_c = @MIM_c -		case when @SoldeLeftToFind < @Solde THEN @SoldeLeftToFind ELSE @Solde end
				IF @Compte = 'ICQ' AND @ICQ + @ICQ_c > 0			set @ICQ_c = @ICQ_c -		case when @SoldeLeftToFind < @Solde THEN @SoldeLeftToFind ELSE @Solde end
				IF @Compte = 'IMQ' AND @IMQ + @IMQ_c > 0			set @IMQ_c = @IMQ_c -		case when @SoldeLeftToFind < @Solde THEN @SoldeLeftToFind ELSE @Solde end
				IF @Compte = 'III' AND @III + @III_c > 0			set @III_c = @III_c -		case when @SoldeLeftToFind < @Solde THEN @SoldeLeftToFind ELSE @Solde end
				IF @Compte = 'IIQ' AND @IIQ + @IIQ_c > 0			set @IIQ_c = @IIQ_c -		case when @SoldeLeftToFind < @Solde THEN @SoldeLeftToFind ELSE @Solde end
				IF @Compte = 'IQI' AND @IQI + @IQI_c > 0			set @IQI_c = @IQI_c -		case when @SoldeLeftToFind < @Solde THEN @SoldeLeftToFind ELSE @Solde end
			
				set @SoldeLeftToFind = case 
										WHEN @Solde >= @SoldeLeftToFind then 0
										else @SoldeLeftToFind - @Solde
										end
		
				end

			set @i = @i + 1
			end
	
		end
	
	IF @INS < 0
		begin
		
		set @INS_c = abs(@INS)
		set @SoldeLeftToFind = abs(@INS)
		
		set @i = 1
		while @i <= 12 and @SoldeLeftToFind > 0 --abs(@inm_c) <> abs(@INM)
			begin
			select 
				@Solde = solde ,
				@Compte = cpt
			from 
				@tblSolde 
			where 
				cpt = (select INS from tblOPER_OrdreAttributionPerteARI A where A.Ordre = @i)
	
			if @Solde > 0 
				begin
				
				update @tblSolde 
				set 
					solde = case 
							when @Solde >= @SoldeLeftToFind then solde - @SoldeLeftToFind 
							ELSE 0
							end
				where cpt = (select INS from tblOPER_OrdreAttributionPerteARI A where A.Ordre = @i)

				--print @Compte + ' ' + cast(@SoldeLeftToFind as varchar(10))
				--print @Solde
				
				IF @Compte = 'INM' AND @INM + @INM_c > 0			set @INM_c = @INM_c -		case when @SoldeLeftToFind < @Solde THEN @SoldeLeftToFind ELSE @Solde end
				IF @Compte = 'ITR' AND @ITR + @ITR_c > 0			set @ITR_c = @ITR_c -		case when @SoldeLeftToFind < @Solde THEN @SoldeLeftToFind ELSE @Solde end
				IF @Compte = 'INS' AND @INS + @INS_c > 0			set @INS_c = @INS_c -		case when @SoldeLeftToFind < @Solde THEN @SoldeLeftToFind ELSE @Solde end
				IF @Compte = 'ISPLUS' AND @ISPlus + @ISPlus_c > 0	set @ISPlus_c = @ISPlus_c - case when @SoldeLeftToFind < @Solde THEN @SoldeLeftToFind ELSE @Solde end
				IF @Compte = 'IBC' AND @IBC + @IBC_c > 0			set @IBC_c = @IBC_c -		case when @SoldeLeftToFind < @Solde THEN @SoldeLeftToFind ELSE @Solde end
				IF @Compte = 'IST' AND @IST + @IST_c > 0			set @IST_c = @IST_c -		case when @SoldeLeftToFind < @Solde THEN @SoldeLeftToFind ELSE @Solde end
				IF @Compte = 'MIM' AND @MIM + @MIM_c > 0			set @MIM_c = @MIM_c -		case when @SoldeLeftToFind < @Solde THEN @SoldeLeftToFind ELSE @Solde end
				IF @Compte = 'ICQ' AND @ICQ + @ICQ_c > 0			set @ICQ_c = @ICQ_c -		case when @SoldeLeftToFind < @Solde THEN @SoldeLeftToFind ELSE @Solde end
				IF @Compte = 'IMQ' AND @IMQ + @IMQ_c > 0			set @IMQ_c = @IMQ_c -		case when @SoldeLeftToFind < @Solde THEN @SoldeLeftToFind ELSE @Solde end
				IF @Compte = 'III' AND @III + @III_c > 0			set @III_c = @III_c -		case when @SoldeLeftToFind < @Solde THEN @SoldeLeftToFind ELSE @Solde end
				IF @Compte = 'IIQ' AND @IIQ + @IIQ_c > 0			set @IIQ_c = @IIQ_c -		case when @SoldeLeftToFind < @Solde THEN @SoldeLeftToFind ELSE @Solde end
				IF @Compte = 'IQI' AND @IQI + @IQI_c > 0			set @IQI_c = @IQI_c -		case when @SoldeLeftToFind < @Solde THEN @SoldeLeftToFind ELSE @Solde end
			
				set @SoldeLeftToFind = case 
										WHEN @Solde >= @SoldeLeftToFind then 0
										else @SoldeLeftToFind - @Solde
										end
		
				end

			set @i = @i + 1
			end
	
		end
	
	IF @ISPlus < 0
		begin
		
		set @ISPlus_c = abs(@ISPlus)
		set @SoldeLeftToFind = abs(@ISPlus)
		
		set @i = 1
		while @i <= 12 and @SoldeLeftToFind > 0 --abs(@inm_c) <> abs(@INM)
			begin
			select 
				@Solde = solde ,
				@Compte = cpt
			from 
				@tblSolde 
			where 
				cpt = (select ISPlus from tblOPER_OrdreAttributionPerteARI A where A.Ordre = @i)
	
			if @Solde > 0 
				begin
				
				update @tblSolde 
				set 
					solde = case 
							when @Solde >= @SoldeLeftToFind then solde - @SoldeLeftToFind 
							ELSE 0
							end
				where cpt = (select ISPlus from tblOPER_OrdreAttributionPerteARI A where A.Ordre = @i)

				--print @SoldeLeftToFind
				
				IF @Compte = 'INM' AND @INM + @INM_c > 0			set @INM_c = @INM_c -		case when @SoldeLeftToFind < @Solde THEN @SoldeLeftToFind ELSE @Solde end
				IF @Compte = 'ITR' AND @ITR + @ITR_c > 0			set @ITR_c = @ITR_c -		case when @SoldeLeftToFind < @Solde THEN @SoldeLeftToFind ELSE @Solde end
				IF @Compte = 'INS' AND @INS + @INS_c > 0			set @INS_c = @INS_c -		case when @SoldeLeftToFind < @Solde THEN @SoldeLeftToFind ELSE @Solde end
				IF @Compte = 'ISPLUS' AND @ISPlus + @ISPlus_c > 0	set @ISPlus_c = @ISPlus_c - case when @SoldeLeftToFind < @Solde THEN @SoldeLeftToFind ELSE @Solde end
				IF @Compte = 'IBC' AND @IBC + @IBC_c > 0			set @IBC_c = @IBC_c -		case when @SoldeLeftToFind < @Solde THEN @SoldeLeftToFind ELSE @Solde end
				IF @Compte = 'IST' AND @IST + @IST_c > 0			set @IST_c = @IST_c -		case when @SoldeLeftToFind < @Solde THEN @SoldeLeftToFind ELSE @Solde end
				IF @Compte = 'MIM' AND @MIM + @MIM_c > 0			set @MIM_c = @MIM_c -		case when @SoldeLeftToFind < @Solde THEN @SoldeLeftToFind ELSE @Solde end
				IF @Compte = 'ICQ' AND @ICQ + @ICQ_c > 0			set @ICQ_c = @ICQ_c -		case when @SoldeLeftToFind < @Solde THEN @SoldeLeftToFind ELSE @Solde end
				IF @Compte = 'IMQ' AND @IMQ + @IMQ_c > 0			set @IMQ_c = @IMQ_c -		case when @SoldeLeftToFind < @Solde THEN @SoldeLeftToFind ELSE @Solde end
				IF @Compte = 'III' AND @III + @III_c > 0			set @III_c = @III_c -		case when @SoldeLeftToFind < @Solde THEN @SoldeLeftToFind ELSE @Solde end
				IF @Compte = 'IIQ' AND @IIQ + @IIQ_c > 0			set @IIQ_c = @IIQ_c -		case when @SoldeLeftToFind < @Solde THEN @SoldeLeftToFind ELSE @Solde end
				IF @Compte = 'IQI' AND @IQI + @IQI_c > 0			set @IQI_c = @IQI_c -		case when @SoldeLeftToFind < @Solde THEN @SoldeLeftToFind ELSE @Solde end
			
				set @SoldeLeftToFind = case 
										WHEN @Solde >= @SoldeLeftToFind then 0
										else @SoldeLeftToFind - @Solde
										end
		
				end

			set @i = @i + 1
			end
		
		end
	
	IF @IBC < 0
		begin
		
		set @IBC_c = abs(@IBC)
		set @SoldeLeftToFind = abs(@IBC)
		
		set @i = 1
		while @i <= 12 and @SoldeLeftToFind > 0 --abs(@inm_c) <> abs(@INM)
			begin
			select 
				@Solde = solde ,
				@Compte = cpt
			from 
				@tblSolde 
			where 
				cpt = (select IBC from tblOPER_OrdreAttributionPerteARI A where A.Ordre = @i)
	
			if @Solde > 0 
				begin
				
				update @tblSolde 
				set 
					solde = case 
							when @Solde >= @SoldeLeftToFind then solde - @SoldeLeftToFind 
							ELSE 0
							end
				where cpt = (select IBC from tblOPER_OrdreAttributionPerteARI A where A.Ordre = @i)

				--print @Compte + ' ' + cast(@SoldeLeftToFind as varchar(10))
				--print @Solde
				
				IF @Compte = 'INM' AND @INM + @INM_c > 0			set @INM_c = @INM_c -		case when @SoldeLeftToFind < @Solde THEN @SoldeLeftToFind ELSE @Solde end
				IF @Compte = 'ITR' AND @ITR + @ITR_c > 0			set @ITR_c = @ITR_c -		case when @SoldeLeftToFind < @Solde THEN @SoldeLeftToFind ELSE @Solde end
				IF @Compte = 'INS' AND @INS + @INS_c > 0			set @INS_c = @INS_c -		case when @SoldeLeftToFind < @Solde THEN @SoldeLeftToFind ELSE @Solde end
				IF @Compte = 'ISPLUS' AND @ISPlus + @ISPlus_c > 0	set @ISPlus_c = @ISPlus_c - case when @SoldeLeftToFind < @Solde THEN @SoldeLeftToFind ELSE @Solde end
				IF @Compte = 'IBC' AND @IBC + @IBC_c > 0			set @IBC_c = @IBC_c -		case when @SoldeLeftToFind < @Solde THEN @SoldeLeftToFind ELSE @Solde end
				IF @Compte = 'IST' AND @IST + @IST_c > 0			set @IST_c = @IST_c -		case when @SoldeLeftToFind < @Solde THEN @SoldeLeftToFind ELSE @Solde end
				IF @Compte = 'MIM' AND @MIM + @MIM_c > 0			set @MIM_c = @MIM_c -		case when @SoldeLeftToFind < @Solde THEN @SoldeLeftToFind ELSE @Solde end
				IF @Compte = 'ICQ' AND @ICQ + @ICQ_c > 0			set @ICQ_c = @ICQ_c -		case when @SoldeLeftToFind < @Solde THEN @SoldeLeftToFind ELSE @Solde end
				IF @Compte = 'IMQ' AND @IMQ + @IMQ_c > 0			set @IMQ_c = @IMQ_c -		case when @SoldeLeftToFind < @Solde THEN @SoldeLeftToFind ELSE @Solde end
				IF @Compte = 'III' AND @III + @III_c > 0			set @III_c = @III_c -		case when @SoldeLeftToFind < @Solde THEN @SoldeLeftToFind ELSE @Solde end
				IF @Compte = 'IIQ' AND @IIQ + @IIQ_c > 0			set @IIQ_c = @IIQ_c -		case when @SoldeLeftToFind < @Solde THEN @SoldeLeftToFind ELSE @Solde end
				IF @Compte = 'IQI' AND @IQI + @IQI_c > 0			set @IQI_c = @IQI_c -		case when @SoldeLeftToFind < @Solde THEN @SoldeLeftToFind ELSE @Solde end
			
				set @SoldeLeftToFind = case 
										WHEN @Solde >= @SoldeLeftToFind then 0
										else @SoldeLeftToFind - @Solde
										end
		
				end

			set @i = @i + 1
			end
	
		end

	IF @IST < 0
		begin
		
		set @IST_c = abs(@IST)
		set @SoldeLeftToFind = abs(@IST)
		
		set @i = 1
		while @i <= 12 and @SoldeLeftToFind > 0 --abs(@inm_c) <> abs(@INM)
			begin
			select 
				@Solde = solde ,
				@Compte = cpt
			from 
				@tblSolde 
			where 
				cpt = (select IST from tblOPER_OrdreAttributionPerteARI A where A.Ordre = @i)
	
			if @Solde > 0 
				begin
				
				update @tblSolde 
				set 
					solde = case 
							when @Solde >= @SoldeLeftToFind then solde - @SoldeLeftToFind 
							ELSE 0
							end
				where cpt = (select IST from tblOPER_OrdreAttributionPerteARI A where A.Ordre = @i)

				--print @Compte + ' ' + cast(@SoldeLeftToFind as varchar(10))
				--print @Solde
				
				IF @Compte = 'INM' AND @INM + @INM_c > 0			set @INM_c = @INM_c -		case when @SoldeLeftToFind < @Solde THEN @SoldeLeftToFind ELSE @Solde end
				IF @Compte = 'ITR' AND @ITR + @ITR_c > 0			set @ITR_c = @ITR_c -		case when @SoldeLeftToFind < @Solde THEN @SoldeLeftToFind ELSE @Solde end
				IF @Compte = 'INS' AND @INS + @INS_c > 0			set @INS_c = @INS_c -		case when @SoldeLeftToFind < @Solde THEN @SoldeLeftToFind ELSE @Solde end
				IF @Compte = 'ISPLUS' AND @ISPlus + @ISPlus_c > 0	set @ISPlus_c = @ISPlus_c - case when @SoldeLeftToFind < @Solde THEN @SoldeLeftToFind ELSE @Solde end
				IF @Compte = 'IBC' AND @IBC + @IBC_c > 0			set @IBC_c = @IBC_c -		case when @SoldeLeftToFind < @Solde THEN @SoldeLeftToFind ELSE @Solde end
				IF @Compte = 'IST' AND @IST + @IST_c > 0			set @IST_c = @IST_c -		case when @SoldeLeftToFind < @Solde THEN @SoldeLeftToFind ELSE @Solde end
				IF @Compte = 'MIM' AND @MIM + @MIM_c > 0			set @MIM_c = @MIM_c -		case when @SoldeLeftToFind < @Solde THEN @SoldeLeftToFind ELSE @Solde end
				IF @Compte = 'ICQ' AND @ICQ + @ICQ_c > 0			set @ICQ_c = @ICQ_c -		case when @SoldeLeftToFind < @Solde THEN @SoldeLeftToFind ELSE @Solde end
				IF @Compte = 'IMQ' AND @IMQ + @IMQ_c > 0			set @IMQ_c = @IMQ_c -		case when @SoldeLeftToFind < @Solde THEN @SoldeLeftToFind ELSE @Solde end
				IF @Compte = 'III' AND @III + @III_c > 0			set @III_c = @III_c -		case when @SoldeLeftToFind < @Solde THEN @SoldeLeftToFind ELSE @Solde end
				IF @Compte = 'IIQ' AND @IIQ + @IIQ_c > 0			set @IIQ_c = @IIQ_c -		case when @SoldeLeftToFind < @Solde THEN @SoldeLeftToFind ELSE @Solde end
				IF @Compte = 'IQI' AND @IQI + @IQI_c > 0			set @IQI_c = @IQI_c -		case when @SoldeLeftToFind < @Solde THEN @SoldeLeftToFind ELSE @Solde end
			
				set @SoldeLeftToFind = case 
										WHEN @Solde >= @SoldeLeftToFind then 0
										else @SoldeLeftToFind - @Solde
										end
		
				end

			set @i = @i + 1
			end
	
		end

	IF @ICQ < 0
		begin
		
		set @ICQ_c = abs(@ICQ)
		set @SoldeLeftToFind = abs(@ICQ)
		
		set @i = 1
		while @i <= 12 and @SoldeLeftToFind > 0 --abs(@inm_c) <> abs(@INM)
			begin
			select 
				@Solde = solde ,
				@Compte = cpt
			from 
				@tblSolde 
			where 
				cpt = (select ICQ from tblOPER_OrdreAttributionPerteARI A where A.Ordre = @i)
	
			if @Solde > 0 
				begin
				
				update @tblSolde 
				set 
					solde = case 
							when @Solde >= @SoldeLeftToFind then solde - @SoldeLeftToFind 
							ELSE 0
							end
				where cpt = (select ICQ from tblOPER_OrdreAttributionPerteARI A where A.Ordre = @i)

				--print @Compte + ' ' + cast(@SoldeLeftToFind as varchar(10))
				--print @Solde
				
				IF @Compte = 'INM' AND @INM + @INM_c > 0			set @INM_c = @INM_c -		case when @SoldeLeftToFind < @Solde THEN @SoldeLeftToFind ELSE @Solde end
				IF @Compte = 'ITR' AND @ITR + @ITR_c > 0			set @ITR_c = @ITR_c -		case when @SoldeLeftToFind < @Solde THEN @SoldeLeftToFind ELSE @Solde end
				IF @Compte = 'INS' AND @INS + @INS_c > 0			set @INS_c = @INS_c -		case when @SoldeLeftToFind < @Solde THEN @SoldeLeftToFind ELSE @Solde end
				IF @Compte = 'ISPLUS' AND @ISPlus + @ISPlus_c > 0	set @ISPlus_c = @ISPlus_c - case when @SoldeLeftToFind < @Solde THEN @SoldeLeftToFind ELSE @Solde end
				IF @Compte = 'IBC' AND @IBC + @IBC_c > 0			set @IBC_c = @IBC_c -		case when @SoldeLeftToFind < @Solde THEN @SoldeLeftToFind ELSE @Solde end
				IF @Compte = 'IST' AND @IST + @IST_c > 0			set @IST_c = @IST_c -		case when @SoldeLeftToFind < @Solde THEN @SoldeLeftToFind ELSE @Solde end
				IF @Compte = 'MIM' AND @MIM + @MIM_c > 0			set @MIM_c = @MIM_c -		case when @SoldeLeftToFind < @Solde THEN @SoldeLeftToFind ELSE @Solde end
				IF @Compte = 'ICQ' AND @ICQ + @ICQ_c > 0			set @ICQ_c = @ICQ_c -		case when @SoldeLeftToFind < @Solde THEN @SoldeLeftToFind ELSE @Solde end
				IF @Compte = 'IMQ' AND @IMQ + @IMQ_c > 0			set @IMQ_c = @IMQ_c -		case when @SoldeLeftToFind < @Solde THEN @SoldeLeftToFind ELSE @Solde end
				IF @Compte = 'III' AND @III + @III_c > 0			set @III_c = @III_c -		case when @SoldeLeftToFind < @Solde THEN @SoldeLeftToFind ELSE @Solde end
				IF @Compte = 'IIQ' AND @IIQ + @IIQ_c > 0			set @IIQ_c = @IIQ_c -		case when @SoldeLeftToFind < @Solde THEN @SoldeLeftToFind ELSE @Solde end
				IF @Compte = 'IQI' AND @IQI + @IQI_c > 0			set @IQI_c = @IQI_c -		case when @SoldeLeftToFind < @Solde THEN @SoldeLeftToFind ELSE @Solde end
			
				set @SoldeLeftToFind = case 
										WHEN @Solde >= @SoldeLeftToFind then 0
										else @SoldeLeftToFind - @Solde
										end
		
				end

			set @i = @i + 1
			end
	
		end

	IF @MIM < 0
		begin
		
		set @MIM_c = abs(@MIM)
		set @SoldeLeftToFind = abs(@MIM)
		
		set @i = 1
		while @i <= 12 and @SoldeLeftToFind > 0 --abs(@inm_c) <> abs(@INM)
			begin
			select 
				@Solde = solde ,
				@Compte = cpt
			from 
				@tblSolde 
			where 
				cpt = (select MIM from tblOPER_OrdreAttributionPerteARI A where A.Ordre = @i)
	
			if @Solde > 0 
				begin
				
				update @tblSolde 
				set 
					solde = case 
							when @Solde >= @SoldeLeftToFind then solde - @SoldeLeftToFind 
							ELSE 0
							end
				where cpt = (select MIM from tblOPER_OrdreAttributionPerteARI A where A.Ordre = @i)

				--print @Compte + ' ' + cast(@SoldeLeftToFind as varchar(10))
				--print @Solde
				
				IF @Compte = 'INM' AND @INM + @INM_c > 0			set @INM_c = @INM_c -		case when @SoldeLeftToFind < @Solde THEN @SoldeLeftToFind ELSE @Solde end
				IF @Compte = 'ITR' AND @ITR + @ITR_c > 0			set @ITR_c = @ITR_c -		case when @SoldeLeftToFind < @Solde THEN @SoldeLeftToFind ELSE @Solde end
				IF @Compte = 'INS' AND @INS + @INS_c > 0			set @INS_c = @INS_c -		case when @SoldeLeftToFind < @Solde THEN @SoldeLeftToFind ELSE @Solde end
				IF @Compte = 'ISPLUS' AND @ISPlus + @ISPlus_c > 0	set @ISPlus_c = @ISPlus_c - case when @SoldeLeftToFind < @Solde THEN @SoldeLeftToFind ELSE @Solde end
				IF @Compte = 'IBC' AND @IBC + @IBC_c > 0			set @IBC_c = @IBC_c -		case when @SoldeLeftToFind < @Solde THEN @SoldeLeftToFind ELSE @Solde end
				IF @Compte = 'IST' AND @IST + @IST_c > 0			set @IST_c = @IST_c -		case when @SoldeLeftToFind < @Solde THEN @SoldeLeftToFind ELSE @Solde end
				IF @Compte = 'MIM' AND @MIM + @MIM_c > 0			set @MIM_c = @MIM_c -		case when @SoldeLeftToFind < @Solde THEN @SoldeLeftToFind ELSE @Solde end
				IF @Compte = 'ICQ' AND @ICQ + @ICQ_c > 0			set @ICQ_c = @ICQ_c -		case when @SoldeLeftToFind < @Solde THEN @SoldeLeftToFind ELSE @Solde end
				IF @Compte = 'IMQ' AND @IMQ + @IMQ_c > 0			set @IMQ_c = @IMQ_c -		case when @SoldeLeftToFind < @Solde THEN @SoldeLeftToFind ELSE @Solde end
				IF @Compte = 'III' AND @III + @III_c > 0			set @III_c = @III_c -		case when @SoldeLeftToFind < @Solde THEN @SoldeLeftToFind ELSE @Solde end
				IF @Compte = 'IIQ' AND @IIQ + @IIQ_c > 0			set @IIQ_c = @IIQ_c -		case when @SoldeLeftToFind < @Solde THEN @SoldeLeftToFind ELSE @Solde end
				IF @Compte = 'IQI' AND @IQI + @IQI_c > 0			set @IQI_c = @IQI_c -		case when @SoldeLeftToFind < @Solde THEN @SoldeLeftToFind ELSE @Solde end
			
				set @SoldeLeftToFind = case 
										WHEN @Solde >= @SoldeLeftToFind then 0
										else @SoldeLeftToFind - @Solde
										end
		
				end

			set @i = @i + 1
			end
	
		end

	IF @IIQ < 0
		begin
		
		set @IIQ_c = abs(@IIQ)
		set @SoldeLeftToFind = abs(@IIQ)
		
		set @i = 1
		while @i <= 12 and @SoldeLeftToFind > 0 --abs(@inm_c) <> abs(@INM)
			begin
			select 
				@Solde = solde ,
				@Compte = cpt
			from 
				@tblSolde 
			where 
				cpt = (select IIQ from tblOPER_OrdreAttributionPerteARI A where A.Ordre = @i)
	
			if @Solde > 0 
				begin
				
				update @tblSolde 
				set 
					solde = case 
							when @Solde >= @SoldeLeftToFind then solde - @SoldeLeftToFind 
							ELSE 0
							end
				where cpt = (select IIQ from tblOPER_OrdreAttributionPerteARI A where A.Ordre = @i)

				--print @Compte + ' ' + cast(@SoldeLeftToFind as varchar(10))
				--print @Solde
				
				IF @Compte = 'INM' AND @INM + @INM_c > 0			set @INM_c = @INM_c -		case when @SoldeLeftToFind < @Solde THEN @SoldeLeftToFind ELSE @Solde end
				IF @Compte = 'ITR' AND @ITR + @ITR_c > 0			set @ITR_c = @ITR_c -		case when @SoldeLeftToFind < @Solde THEN @SoldeLeftToFind ELSE @Solde end
				IF @Compte = 'INS' AND @INS + @INS_c > 0			set @INS_c = @INS_c -		case when @SoldeLeftToFind < @Solde THEN @SoldeLeftToFind ELSE @Solde end
				IF @Compte = 'ISPLUS' AND @ISPlus + @ISPlus_c > 0	set @ISPlus_c = @ISPlus_c - case when @SoldeLeftToFind < @Solde THEN @SoldeLeftToFind ELSE @Solde end
				IF @Compte = 'IBC' AND @IBC + @IBC_c > 0			set @IBC_c = @IBC_c -		case when @SoldeLeftToFind < @Solde THEN @SoldeLeftToFind ELSE @Solde end
				IF @Compte = 'IST' AND @IST + @IST_c > 0			set @IST_c = @IST_c -		case when @SoldeLeftToFind < @Solde THEN @SoldeLeftToFind ELSE @Solde end
				IF @Compte = 'MIM' AND @MIM + @MIM_c > 0			set @MIM_c = @MIM_c -		case when @SoldeLeftToFind < @Solde THEN @SoldeLeftToFind ELSE @Solde end
				IF @Compte = 'ICQ' AND @ICQ + @ICQ_c > 0			set @ICQ_c = @ICQ_c -		case when @SoldeLeftToFind < @Solde THEN @SoldeLeftToFind ELSE @Solde end
				IF @Compte = 'IMQ' AND @IMQ + @IMQ_c > 0			set @IMQ_c = @IMQ_c -		case when @SoldeLeftToFind < @Solde THEN @SoldeLeftToFind ELSE @Solde end
				IF @Compte = 'III' AND @III + @III_c > 0			set @III_c = @III_c -		case when @SoldeLeftToFind < @Solde THEN @SoldeLeftToFind ELSE @Solde end
				IF @Compte = 'IIQ' AND @IIQ + @IIQ_c > 0			set @IIQ_c = @IIQ_c -		case when @SoldeLeftToFind < @Solde THEN @SoldeLeftToFind ELSE @Solde end
				IF @Compte = 'IQI' AND @IQI + @IQI_c > 0			set @IQI_c = @IQI_c -		case when @SoldeLeftToFind < @Solde THEN @SoldeLeftToFind ELSE @Solde end
			
				set @SoldeLeftToFind = case 
										WHEN @Solde >= @SoldeLeftToFind then 0
										else @SoldeLeftToFind - @Solde
										end
		
				end

			set @i = @i + 1
			end
	
		end

	IF @IMQ < 0
		begin
		
		set @IMQ_c = abs(@IMQ)
		set @SoldeLeftToFind = abs(@IMQ)
		
		set @i = 1
		while @i <= 12 and @SoldeLeftToFind > 0 --abs(@inm_c) <> abs(@INM)
			begin
			select 
				@Solde = solde ,
				@Compte = cpt
			from 
				@tblSolde 
			where 
				cpt = (select IMQ from tblOPER_OrdreAttributionPerteARI A where A.Ordre = @i)
	
			if @Solde > 0 
				begin
				
				update @tblSolde 
				set 
					solde = case 
							when @Solde >= @SoldeLeftToFind then solde - @SoldeLeftToFind 
							ELSE 0
							end
				where cpt = (select IMQ from tblOPER_OrdreAttributionPerteARI A where A.Ordre = @i)

				--print @Compte + ' ' + cast(@SoldeLeftToFind as varchar(10))
				--print @Solde
				
				IF @Compte = 'INM' AND @INM + @INM_c > 0			set @INM_c = @INM_c -		case when @SoldeLeftToFind < @Solde THEN @SoldeLeftToFind ELSE @Solde end
				IF @Compte = 'ITR' AND @ITR + @ITR_c > 0			set @ITR_c = @ITR_c -		case when @SoldeLeftToFind < @Solde THEN @SoldeLeftToFind ELSE @Solde end
				IF @Compte = 'INS' AND @INS + @INS_c > 0			set @INS_c = @INS_c -		case when @SoldeLeftToFind < @Solde THEN @SoldeLeftToFind ELSE @Solde end
				IF @Compte = 'ISPLUS' AND @ISPlus + @ISPlus_c > 0	set @ISPlus_c = @ISPlus_c - case when @SoldeLeftToFind < @Solde THEN @SoldeLeftToFind ELSE @Solde end
				IF @Compte = 'IBC' AND @IBC + @IBC_c > 0			set @IBC_c = @IBC_c -		case when @SoldeLeftToFind < @Solde THEN @SoldeLeftToFind ELSE @Solde end
				IF @Compte = 'IST' AND @IST + @IST_c > 0			set @IST_c = @IST_c -		case when @SoldeLeftToFind < @Solde THEN @SoldeLeftToFind ELSE @Solde end
				IF @Compte = 'MIM' AND @MIM + @MIM_c > 0			set @MIM_c = @MIM_c -		case when @SoldeLeftToFind < @Solde THEN @SoldeLeftToFind ELSE @Solde end
				IF @Compte = 'ICQ' AND @ICQ + @ICQ_c > 0			set @ICQ_c = @ICQ_c -		case when @SoldeLeftToFind < @Solde THEN @SoldeLeftToFind ELSE @Solde end
				IF @Compte = 'IMQ' AND @IMQ + @IMQ_c > 0			set @IMQ_c = @IMQ_c -		case when @SoldeLeftToFind < @Solde THEN @SoldeLeftToFind ELSE @Solde end
				IF @Compte = 'III' AND @III + @III_c > 0			set @III_c = @III_c -		case when @SoldeLeftToFind < @Solde THEN @SoldeLeftToFind ELSE @Solde end
				IF @Compte = 'IIQ' AND @IIQ + @IIQ_c > 0			set @IIQ_c = @IIQ_c -		case when @SoldeLeftToFind < @Solde THEN @SoldeLeftToFind ELSE @Solde end
				IF @Compte = 'IQI' AND @IQI + @IQI_c > 0			set @IQI_c = @IQI_c -		case when @SoldeLeftToFind < @Solde THEN @SoldeLeftToFind ELSE @Solde end
			
				set @SoldeLeftToFind = case 
										WHEN @Solde >= @SoldeLeftToFind then 0
										else @SoldeLeftToFind - @Solde
										end
		
				end

			set @i = @i + 1
			end
	
		end

	IF @IQI < 0
		begin
		
		set @IQI_c = abs(@IQI)
		set @SoldeLeftToFind = abs(@IQI)
		
		set @i = 1
		while @i <= 12 and @SoldeLeftToFind > 0 --abs(@inm_c) <> abs(@INM)
			begin
			select 
				@Solde = solde ,
				@Compte = cpt
			from 
				@tblSolde 
			where 
				cpt = (select IQI from tblOPER_OrdreAttributionPerteARI A where A.Ordre = @i)
	
			if @Solde > 0 
				begin
				
				update @tblSolde 
				set 
					solde = case 
							when @Solde >= @SoldeLeftToFind then solde - @SoldeLeftToFind 
							ELSE 0
							end
				where cpt = (select IQI from tblOPER_OrdreAttributionPerteARI A where A.Ordre = @i)

				--print @Compte + ' ' + cast(@SoldeLeftToFind as varchar(10))
				--print @Solde
				
				IF @Compte = 'INM' AND @INM + @INM_c > 0			set @INM_c = @INM_c -		case when @SoldeLeftToFind < @Solde THEN @SoldeLeftToFind ELSE @Solde end
				IF @Compte = 'ITR' AND @ITR + @ITR_c > 0			set @ITR_c = @ITR_c -		case when @SoldeLeftToFind < @Solde THEN @SoldeLeftToFind ELSE @Solde end
				IF @Compte = 'INS' AND @INS + @INS_c > 0			set @INS_c = @INS_c -		case when @SoldeLeftToFind < @Solde THEN @SoldeLeftToFind ELSE @Solde end
				IF @Compte = 'ISPLUS' AND @ISPlus + @ISPlus_c > 0	set @ISPlus_c = @ISPlus_c - case when @SoldeLeftToFind < @Solde THEN @SoldeLeftToFind ELSE @Solde end
				IF @Compte = 'IBC' AND @IBC + @IBC_c > 0			set @IBC_c = @IBC_c -		case when @SoldeLeftToFind < @Solde THEN @SoldeLeftToFind ELSE @Solde end
				IF @Compte = 'IST' AND @IST + @IST_c > 0			set @IST_c = @IST_c -		case when @SoldeLeftToFind < @Solde THEN @SoldeLeftToFind ELSE @Solde end
				IF @Compte = 'MIM' AND @MIM + @MIM_c > 0			set @MIM_c = @MIM_c -		case when @SoldeLeftToFind < @Solde THEN @SoldeLeftToFind ELSE @Solde end
				IF @Compte = 'ICQ' AND @ICQ + @ICQ_c > 0			set @ICQ_c = @ICQ_c -		case when @SoldeLeftToFind < @Solde THEN @SoldeLeftToFind ELSE @Solde end
				IF @Compte = 'IMQ' AND @IMQ + @IMQ_c > 0			set @IMQ_c = @IMQ_c -		case when @SoldeLeftToFind < @Solde THEN @SoldeLeftToFind ELSE @Solde end
				IF @Compte = 'III' AND @III + @III_c > 0			set @III_c = @III_c -		case when @SoldeLeftToFind < @Solde THEN @SoldeLeftToFind ELSE @Solde end
				IF @Compte = 'IIQ' AND @IIQ + @IIQ_c > 0			set @IIQ_c = @IIQ_c -		case when @SoldeLeftToFind < @Solde THEN @SoldeLeftToFind ELSE @Solde end
				IF @Compte = 'IQI' AND @IQI + @IQI_c > 0			set @IQI_c = @IQI_c -		case when @SoldeLeftToFind < @Solde THEN @SoldeLeftToFind ELSE @Solde end
			
				set @SoldeLeftToFind = case 
										WHEN @Solde >= @SoldeLeftToFind then 0
										else @SoldeLeftToFind - @Solde
										end
		
				end

			set @i = @i + 1
			end
	
		end

	IF @III < 0
		begin
		
		set @III_c = abs(@III)
		set @SoldeLeftToFind = abs(@III)
		
		set @i = 1
		while @i <= 12 and @SoldeLeftToFind > 0 --abs(@inm_c) <> abs(@INM)
			begin
			select 
				@Solde = solde ,
				@Compte = cpt
			from 
				@tblSolde 
			where 
				cpt = (select III from tblOPER_OrdreAttributionPerteARI A where A.Ordre = @i)
	
			if @Solde > 0 
				begin
				
				update @tblSolde 
				set 
					solde = case 
							when @Solde >= @SoldeLeftToFind then solde - @SoldeLeftToFind 
							ELSE 0
							end
				where cpt = (select III from tblOPER_OrdreAttributionPerteARI A where A.Ordre = @i)

				--print @Compte + ' ' + cast(@SoldeLeftToFind as varchar(10))
				--print @Solde
				
				IF @Compte = 'INM' AND @INM + @INM_c > 0			set @INM_c = @INM_c -		case when @SoldeLeftToFind < @Solde THEN @SoldeLeftToFind ELSE @Solde end
				IF @Compte = 'ITR' AND @ITR + @ITR_c > 0			set @ITR_c = @ITR_c -		case when @SoldeLeftToFind < @Solde THEN @SoldeLeftToFind ELSE @Solde end
				IF @Compte = 'INS' AND @INS + @INS_c > 0			set @INS_c = @INS_c -		case when @SoldeLeftToFind < @Solde THEN @SoldeLeftToFind ELSE @Solde end
				IF @Compte = 'ISPLUS' AND @ISPlus + @ISPlus_c > 0	set @ISPlus_c = @ISPlus_c - case when @SoldeLeftToFind < @Solde THEN @SoldeLeftToFind ELSE @Solde end
				IF @Compte = 'IBC' AND @IBC + @IBC_c > 0			set @IBC_c = @IBC_c -		case when @SoldeLeftToFind < @Solde THEN @SoldeLeftToFind ELSE @Solde end
				IF @Compte = 'IST' AND @IST + @IST_c > 0			set @IST_c = @IST_c -		case when @SoldeLeftToFind < @Solde THEN @SoldeLeftToFind ELSE @Solde end
				IF @Compte = 'MIM' AND @MIM + @MIM_c > 0			set @MIM_c = @MIM_c -		case when @SoldeLeftToFind < @Solde THEN @SoldeLeftToFind ELSE @Solde end
				IF @Compte = 'ICQ' AND @ICQ + @ICQ_c > 0			set @ICQ_c = @ICQ_c -		case when @SoldeLeftToFind < @Solde THEN @SoldeLeftToFind ELSE @Solde end
				IF @Compte = 'IMQ' AND @IMQ + @IMQ_c > 0			set @IMQ_c = @IMQ_c -		case when @SoldeLeftToFind < @Solde THEN @SoldeLeftToFind ELSE @Solde end
				IF @Compte = 'III' AND @III + @III_c > 0			set @III_c = @III_c -		case when @SoldeLeftToFind < @Solde THEN @SoldeLeftToFind ELSE @Solde end
				IF @Compte = 'IIQ' AND @IIQ + @IIQ_c > 0			set @IIQ_c = @IIQ_c -		case when @SoldeLeftToFind < @Solde THEN @SoldeLeftToFind ELSE @Solde end
				IF @Compte = 'IQI' AND @IQI + @IQI_c > 0			set @IQI_c = @IQI_c -		case when @SoldeLeftToFind < @Solde THEN @SoldeLeftToFind ELSE @Solde end
			
				set @SoldeLeftToFind = case 
										WHEN @Solde >= @SoldeLeftToFind then 0
										else @SoldeLeftToFind - @Solde
										end
		
				end

			set @i = @i + 1
			end
	
		end

		SET @EAFB_C = CASE 
				WHEN @INM +@ITR +@INS +@ISPlus +@IBC +@IST +@MIM +@ICQ +@IMQ +@III +@IIQ +@IQI < 0 
					THEN @INM +@ITR +@INS +@ISPlus +@IBC +@IST +@MIM +@ICQ +@IMQ +@III +@IIQ +@IQI 
				ELSE 0 END

/*

	PRINT '@INM_c= ' + CAST( @INM_c AS VARCHAR(10))
	PRINT '@ITR_c= ' + CAST( @ITR_c AS VARCHAR(10))
	PRINT '@INS_c= ' + CAST( @INS_c  AS VARCHAR(10))
	PRINT '@ISPlus_c= ' + CAST( @ISPlus_c AS VARCHAR(10))
	PRINT '@IBC_c= ' + CAST( @IBC_c AS VARCHAR(10))
	PRINT '@IST_c= ' + CAST( @IST_c AS VARCHAR(10))
	PRINT '@MIM_c= ' + CAST( @MIM_c AS VARCHAR(10))
	PRINT '@ICQ_c= ' + CAST( @ICQ_c AS VARCHAR(10))
	PRINT '@IMQ_c= ' + CAST( @IMQ_c AS VARCHAR(10))
	PRINT '@III_c= ' + CAST( @III_c AS VARCHAR(10))
	PRINT '@IIQ_c= ' + CAST( @IIQ_c AS VARCHAR(10))
	PRINT '@IQI_c= ' + CAST( @IQI_c AS VARCHAR(10))
	PRINT '@EAFB_c= ' + CAST( @EAFB_c AS VARCHAR(10))
*/

	select 
		--TOTAL = @INM +@ITR +@INS +@ISPlus +@IBC +@IST +@MIM +@ICQ +@IMQ +@III +@IIQ +@IQI,
		INM_c = @INM_c,
		ITR_c = @ITR_c,
		INS_c = @INS_c,
		ISPlus_c = @ISPlus_c,
		IBC_c = @IBC_c,
		IST_c= @IST_c,
		MIM_c= @MIM_c,
		ICQ_c= @ICQ_c,
		IMQ_c= @IMQ_c,
		III_c= @III_c,
		IIQ_c= @IIQ_c,
		IQI_c= @IQI_c,
		EAFB_c=@EAFB_c
	
End